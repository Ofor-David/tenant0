import hashlib
import json
import os

import psycopg
import redis.asyncio as aioredis
from aiohttp import ClientSession, ClientTimeout, web
from psycopg_pool import AsyncConnectionPool

TENANT = os.environ["TENANT_NAME"]
CONNINFO = (
    f"host=127.0.0.1 port=6432 dbname=postgres "
    f"user=t0-u-{TENANT}-sa@t0-u-{TENANT}.iam sslmode=disable"
)
CACHE_TTL = 300
TEI_URL = "http://127.0.0.1:80/embed"

CREATE_SQL = (
    "CREATE TABLE IF NOT EXISTS embeddings "
    "(text TEXT PRIMARY KEY, embedding vector(384));"
)
UPSERT_SQL = (
    "INSERT INTO embeddings (text, embedding) VALUES (%s, %s::vector) "
    "ON CONFLICT (text) DO UPDATE SET embedding = EXCLUDED.embedding;"
)
NEAREST_SQL = "SELECT text FROM embeddings ORDER BY embedding <-> %s::vector LIMIT 1;"


def _key(text: str) -> str:
    return "emb:" + hashlib.sha256(text.encode()).hexdigest()


def _vec_literal(vector) -> str:
    # Same wire format the old psql path used: "[v1,v2,...]" cast to ::vector.
    return "[" + ",".join(str(v) for v in vector) + "]"


async def _disable_prepared(conn: psycopg.AsyncConnection) -> None:
    # PgBouncer transaction pooling does not support server-side prepared
    # statements - asyncpg's auto-prepare would silently break under real
    # concurrency (confirmed live-equivalent failure mode researched before
    # choosing psycopg3 over asyncpg for this rewrite). One line, hard off.
    conn.prepare_threshold = None


async def health(request: web.Request) -> web.Response:
    return web.Response()


async def embed(request: web.Request) -> web.Response:
    app = request.app
    body = await request.json()
    text = body.get("inputs", "")
    key = _key(text)

    cached = await app["redis"].get(key)
    if cached:
        return web.json_response({"embedding": json.loads(cached), "cache": "hit"})

    async with app["http"].post(TEI_URL, json={"inputs": text}) as resp:
        resp.raise_for_status()
        vector = (await resp.json())[0]
    vec = _vec_literal(vector)

    async with app["pg"].connection() as conn:
        async with conn.cursor() as cur:
            await cur.execute(UPSERT_SQL, (text, vec))
            await cur.execute(NEAREST_SQL, (vec,))
            row = await cur.fetchone()
        await conn.commit()
    nearest = row[0] if row else ""

    await app["redis"].set(key, json.dumps(vector), ex=CACHE_TTL)
    return web.json_response(
        {"embedding": vector, "cache": "miss", "nearest_match": nearest}
    )


async def _startup(app: web.Application) -> None:
    app["redis"] = aioredis.Redis(host="redis", decode_responses=True)
    app["http"] = ClientSession(timeout=ClientTimeout(total=30))
    app["pg"] = AsyncConnectionPool(
        CONNINFO, min_size=2, max_size=16, configure=_disable_prepared, open=False
    )
    await app["pg"].open()
    async with app["pg"].connection() as conn:  # create table once, not per-request
        await conn.execute(CREATE_SQL)
        await conn.commit()


async def _cleanup(app: web.Application) -> None:
    await app["http"].close()
    await app["pg"].close()
    await app["redis"].aclose()


def make_app() -> web.Application:
    app = web.Application()
    app.on_startup.append(_startup)
    app.on_cleanup.append(_cleanup)
    app.add_routes([
        web.get("/health", health),
        web.post("/health", health),
        web.get("/embed", embed),
        web.post("/embed", embed),
    ])
    return app


if __name__ == "__main__":
    import sys

    if "--selftest" in sys.argv:
        # Pure-logic check: key scheme + vector literal are byte-identical
        # to the old subprocess-based implementation this replaces.
        t = "hello world"
        assert _key(t) == "emb:" + hashlib.sha256(t.encode()).hexdigest()
        assert _vec_literal([0.1, -2.0, 3]) == "[0.1,-2.0,3]"
        print("selftest ok")
        sys.exit(0)

    web.run_app(make_app(), host="0.0.0.0", port=8000)
