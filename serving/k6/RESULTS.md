# §8.5 Load Test — Investigation Log

**SLO (design §5.3):** cache-hit p99 < 150ms, cache-miss p99 < 500ms, 50 req/s/tenant sustained.
**Test:** `serving/k6/load-test.js`, two `constant-arrival-rate` scenarios at 50 iterations/s for 30s each — `cache_hit` repeats one pre-warmed text, `cache_miss` uses a unique text every call (guaranteed real TEI + DB round trip). Run against `tenant-n` (small tier) through the real edge (`Gateway` -> `edge-router` -> `tei` Service -> `app`/`TEI`/`cloud-sql-proxy`).

**Final result: SLO not numerically met, but the system went from routinely failing under load to reliably succeeding under load.** Every fix below is a real, live-diagnosed change — none were guesses applied blind; each was chosen because a prior run's evidence pointed at it.

---

## Correctness bugs fixed before performance testing was meaningful

These made cache-miss *work at all* — without them there was nothing valid to load-test:

| Bug | Symptom | Fix |
|---|---|---|
| No `redis` Service, only a Deployment | App's `redis-cli -h redis` failed: "Name has no usable address" | Added `redis-service` (ClusterIP) |
| Wrong database name (`t0-u-<tenant>-db`) | `psql: database "t0-u-tenant-n-db" does not exist` | That string is the Cloud SQL *instance* name, not a database inside it — connect to `postgres`, same as `pgvector-migration` already does |
| `psql -c` doesn't do `:'var'` substitution | Every bound query was a silent syntax error | Pipe SQL via stdin instead of `-c` — substitution only fires for script/stdin input |
| `NetworkPolicy` allowed port 80, not 8000 | `edge-router` timed out reaching `tei` Service with no error either side | NetworkPolicy ports match the pod's real `containerPort`, not the Service port — `tei-service`'s `targetPort` is 8000 (the `app` container) |
| `provider-kubernetes-tenant-resources` ClusterRole missing `rolebindings`, `services`, `configmaps` | Crossplane's provider-kubernetes couldn't manage those resource types | Added each as the need for it appeared |

---

## Performance investigation: lever by lever

| # | Lever | cache-hit p99 | cache-miss p99 | Success rate | Notes |
|---|---|---|---|---|---|
| 0 | **Baseline** (250m CPU limits everywhere, no pooling) | 10.39s | 30.24s | 64.23% | avg cache-miss 12.1s, throughput only ~23 req/s vs 50 target |
| 1 | `edge-router` + `app` CPU limit 250m→1000m | **415.7ms** (25x) | 30.25s (unchanged) | 92.50% | Confirmed edge-router/app were genuinely CPU-throttled despite nodes sitting at ~20% actual use — container *limits*, not node capacity, were the wall |
| 2 | TEI CPU limit 1→2 cores (replicas stayed 1 — 2nd replica couldn't schedule, node pool at its Terraform-fixed max) | ~290-340ms avg (unaffected, as expected) | ~30s (unmoved — p90/p95 already 30.24s/30.25s) | 93.68% | **Zero effect** — this is the key diagnostic result: if TEI were compute-bound, doubling cores would have helped at least partially. It didn't, which ruled out TEI/compute entirely and pointed at something else in the chain |
| 3 | Opus-assisted reasoning session diagnosed the untouched dial: `cloud-sql-proxy` CPU limit 100m→1000m (request kept at 50m — bumping the request too made the pod briefly unschedulable, reverted) | 1.07s (noise/regression) | 30.68s (still clamped) — but **avg 9.34s, median 8.42s, min 377ms** (down from min 3.4s) | 87.70% | First real movement in the *typical* case — confirmed connection-handshake cost was part of it, but the tail stayed pinned near the clamp |
| 4 | `workloads_max_node_count` 4→5 (Terraform) | — | — | — | Pure headroom, not itself perf-tested in isolation — needed so the next change (PgBouncer, a 4th container) could schedule at all |
| 5 | **PgBouncer sidecar** (transaction pooling, `app`'s 3 `psql` calls per miss now reuse pooled connections to `cloud-sql-proxy` instead of each paying a fresh TLS+IAM handshake) | 455.92ms | 30.23s (still clamped) — but **avg 4.12s, median 2.52s** (3.3x better than lever 3), **min 240ms** | 80.15% | Took 4 live sub-fixes to get working: ConfigMap-mount/apk install path collision, "should not run as root" (needed `su-exec` + explicit `adduser`, the apk package doesn't create the user outside its unused OpenRC script), `trust` auth still requiring a known username (added per-tenant `userlist.txt`), and a Crossplane field-path escaping bug (`userlist\.txt` created a nested key instead of the flat one PgBouncer needed — fixed with bracket notation) |
| 6 | **`request_queue_size` 5→128** on both `edge-router`'s and `app`'s `http.server.ThreadingHTTPServer` | **329.3ms** | **13.18s** (finally moved off the 30s clamp) | **99.13%** | The actual remaining ceiling. Diagnosed by noticing `edge-router`'s own 502 count (549) matched k6's failed-check count exactly, while TEI's own logs showed every single embed completing in 10-90ms with near-zero queue time (ruling TEI out directly) and the `app` container logged zero errors (ruling its logic out). Python's `http.server` defaults to a TCP accept backlog of 5 — under 100+ concurrent connections, new connections queued at the OS accept level long enough to blow past the 30s client-side timeout, without either server ever seeing or logging the request |

---

## Final numbers vs SLO

| Scenario | Target | Achieved | Gap |
|---|---|---|---|
| cache-hit p99 | < 150ms | 329.3ms | ~2.2x over |
| cache-miss p99 | < 500ms | 13.18s | ~26x over |
| Success rate | (implicit: requests complete) | 99.13% (was 64.23% at baseline) | — |

## Honest assessment of what's left

The system now **works reliably under load** rather than failing under it — that's the real change across this investigation, even though the stated latency SLO isn't numerically met. The remaining gap is architectural, not a config knob:

- `app`'s per-request design spawns 5 subprocesses (2 `redis-cli`, 3 `psql`) per cache-miss, each a fresh OS process fork/exec. PgBouncer removed the *connection* cost; the *process-spawn* cost is still there every request.
- A real fix is a rewrite: a persistent Python process holding one Postgres connection (or a small pool) and one Redis connection, instead of shelling out to CLIs per request — removing the subprocess overhead entirely, not just the connection overhead.
- Everything in the serving path (`edge-router`, `app`, TEI) is a single replica; horizontal scaling was blocked this session by the `workloads` node pool's request-based scheduling ceiling, not by design.

Both are named, credible upgrade paths — not vague hand-waving — but out of scope for what could be safely iterated on before the GCP credit deadline.
