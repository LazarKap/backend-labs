# backend-labs

A small online store in Go, built from scratch, put under constant load and broken one scenario at a
time.

I run production systems on top of all of this already: load balancers, connection pools, caches,
queues, Postgres under contention, Kubernetes. This is a side project to build the layer underneath by
hand, for fun and for depth. The HTTP server on raw TCP, the router, the pool, the cache, the load
balancer, the queue, the rate limiter, a small key-value store. Standard library for primitives only
(sockets, buffers, JSON, TLS) plus a Postgres driver. No frameworks, no AI.

A second server generates traffic 24/7 and things go wrong on purpose. Each time, I find the cause,
fix it properly, and write down what I decided and what I rejected.

The store is the excuse. The output is the decision records in `labs/` and `docs/request-lifecycle.md`,
one request followed end to end through code I wrote.

## How it works

There are two servers. `app` runs the store. `world` runs Prometheus, Grafana and a traffic generator
that never stops. `world` is operated by Claude, playing the role of users, bots, a flaky payment
provider and whoever else the scenario needs. It shows me what the outside sees: request rate, status
codes, latency as measured by the client. Anything the app knows about itself, I have to build.

One scenario is open at a time:

1. Claude writes a card in `labs/week-NN/card.md` describing what's happening and what "fixed" looks
   like in numbers, then changes the traffic. Usually something on the dashboard goes red.
2. I dig in, read, design, build, deploy. If I'm stuck Claude asks questions or points me at things to
   read. It doesn't tell me the answer.
3. When the scenario's panel has been green for 24 hours, Claude tries to break what I built and reviews
   the design.
4. I write the ADR and the lab log, commit, and the next card arrives.

No fixed schedule. Work hours and evenings when I have time. If a scenario drags past two weeks I scope
it down, note what I skipped, and move on.

## Rules

- Go standard library for primitives (`net`, `bufio`, `io`, `os`, `sync`, `encoding/json`, `crypto/tls`)
  and `pgx` for Postgres until scenario 05 replaces it. Not `net/http`. Anything that is a component, I
  write. Anything else I pull in needs an ADR explaining why.
- Build a component when a scenario makes me need it, not before.
- Some things I'm not building: TLS, DNS, TCP, the database that holds orders (that stays Postgres),
  Kubernetes, and the measuring stick on `world` (Prometheus, Grafana, k6). Kubernetes is where I stop
  building and learn to run things instead. The measuring stick stays independent or the numbers mean
  nothing.
- Side quests are fine if they're bounded. Writing a database engine is not bounded, so no.
- No AI anywhere near `app/`. No completion, no generated code, no "fix this". Docs, books and library
  source are fine. Stack Overflow after I've been stuck for 20 minutes.
- Claude never touches app code. It writes cards, traffic profiles, chaos scripts and reviews, and tells
  me when my fix is a band-aid.
- Every scenario ends with an ADR that includes what I rejected.
- If there's no measurement, it didn't happen.
- A fix that has to be repeated in every caller is in the wrong place.
- Green on the dashboard isn't done. Green for 24 hours plus the ADR is done.

## The store

Products with stock, a cart, checkout, orders. Postgres. Five endpoints in scenario 02 and nothing more
until a scenario asks for it. On top of steady browsing traffic there'll be "drops": a product with
limited stock going on sale at a set time so everyone shows up at once. Both kinds of traffic matter,
some problems only show up when they overlap.

## Scenarios

The order is driven by need. A component shows up in the week its absence starts to hurt.

| # | Scenario | What it's about | Built that week |
|---|---|---|---|
| 01 | The world is already calling | TCP, HTTP/1.1 parsing, keep-alive, timeouts, deploying by hand | HTTP server |
| 02 | It's supposed to be a store | Project layout, routing, Postgres, migrations | Router, middleware, config, migrations |
| 03 | We can't see anything | Percentiles, labels, cardinality, structured logs, a dashboard | Metrics endpoint, logger |
| 04 | 10× surge at drop time | Pool sizing, indexes, timeouts, limits | Connection pool |
| 05 | The last dependency | Postgres wire protocol, SCRAM auth, extended query, type decoding | Postgres driver, `pgx` removed |
| 06 | Stock went negative | Transactions, isolation, locking, idempotency | |
| 07 | Thundering herd on the hot product | Caching, TTLs, stampedes, coalescing | In-process cache |
| 08 | One instance isn't enough | Multiple instances, cache coherence, health checks | Load balancer v1 |
| 09 | Backends come and go | Discovery, heartbeats, membership, stale entries | Service registry |
| 10 | Deploy during a drop | Zero downtime, readiness vs liveness, draining, rollback | Deploy tool, load balancer v2 |
| 11 | Shared cache (two weeks) | Append-only logs, hash index, fsync, crash recovery, compaction | Bitcask-style KV store |
| 12 | Shared cache, served | Wire protocol, TTL, eviction across instances | Cache server on top of it |
| 13 | The cache node died | Leader and follower, log shipping, catch-up, failover without consensus | KV replication |
| 14 | Payment provider gets slow | Timeouts, circuit breakers, bulkheads, fallbacks | |
| 15 | Checkout takes too long | Async work, acks, retries, dead letters, graceful shutdown | Durable queue, worker |
| 16 | Search is slow | Tokenising, inverted index, ranking, index updates on stock change | Search index |
| 17 | The reporting query | Prod vs analytics load, statement timeouts, isolating workloads | |
| 18 | Reads drown writes | Read replica, read/write split, invalidation | |
| 19 | Database fails over | Reconnect storms, backoff, jitter, retry budgets | |
| 20 | Abuse and bots | Rate limiting, per-user limits, backpressure, what 429 means | Rate limiter |
| 21 | Carts pile up | Background jobs vs live traffic, batching, scheduling | Job scheduler |
| 22 | What's in a container | Namespaces, cgroups, rootfs, what Docker actually does | Mini container runtime |
| 23 | Move it to Kubernetes | k3s or a managed cluster, deployments, services, probes. My LB vs an ingress | |
| 24 | Pods die, node is full | Autoscaling under load, limits, disruption budgets | |
| 25 | Config and secrets | Rotation without restarts, reload semantics | |
| 26 | The warehouse feed | Stock changing from a second source while people buy | |
| 27 | Incident week | Something breaks without warning. Run it, write the postmortem | |
| 28 | Wrap up | Finish the lifecycle doc, load report, maybe a blog post | |

Roughly 30 weeks of work if I did one a week. I won't, so it'll take longer.

## Who writes where

| Path | Whose | What |
|---|---|---|
| `app/` | me | The store and every component. No AI touches this. |
| `docs/request-lifecycle.md` | me | One request traced end to end, a row per component |
| `labs/week-NN/adr.md`, `log.md`, `metrics.png` | me | Decision record, lab log, dashboard screenshot |
| `labs/week-NN/card.md` | Claude | The scenario |
| `labs/_templates/` | Claude | Blank ADR and log |
| `world/` | Claude | Provisioning, dashboards, k6 profiles, chaos scripts, fake payment provider |
| the READMEs | both | |

Claude's commits are authored as `world (Claude)`, mine as me, so `git log --author` separates the two
sides.

## Infrastructure

Two DigitalOcean droplets. `world` (2 vCPU, 2 GB) has Prometheus, Grafana, k6 and later a fake payment
provider. Claude sets it up. `app` (1 vCPU, 1 GB) is bare Ubuntu with Postgres and the store, kept small
on purpose so I hit limits early. I deploy to it by hand until a scenario makes that painful.

## Status

Planning. Scenario 01 opens when `world` starts sending traffic to an `app` droplet that doesn't answer
yet.
