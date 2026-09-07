# Replaces the previous subprocess-per-request design (python:3.12-alpine +
# apk-installed psql/redis-cli shelled out to on every request) - confirmed
# live that spawning 5 OS processes per cache-miss was the real remaining
# latency ceiling after CPU limits and connection pooling had already been
# fixed. This holds one persistent Postgres pool and one persistent Redis
# connection instead.
#
# All three deps ship musllinux_1_2 wheels - confirmed live via `pip install`
# on this exact base image before pinning: no compiler, no apk build-base,
# just wheel downloads. Prebuilt image (not apk+pip at pod startup, unlike
# edge-router/the old app) because this is a diagnosed serving hot path -
# a PyPI hiccup or a floating version on every pod restart is a new failure
# mode this specific container shouldn't carry. TEI is already built this
# way; reusing the same pipeline is marginal cost, not a new capability.
FROM python:3.13-alpine
RUN pip install --no-cache-dir \
        "psycopg[binary]==3.3.5" \
        "psycopg-pool==3.3.1" \
        "redis==6.4.0" \
        "aiohttp==3.12.15"
COPY app.py /app/app.py
WORKDIR /app
EXPOSE 8000
CMD ["python", "app.py"]
