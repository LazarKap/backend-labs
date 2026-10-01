# backend-labs

A small online store in Go, built from scratch, put under constant load and broken one scenario at a
time.

I run production systems on top of all of this already: load balancers, connection pools, caches,
queues, Postgres under contention, Kubernetes. This is a side project to build the layer underneath by
hand, for fun and for depth. The HTTP server on raw TCP, the router, the pool, the Postgres driver, the
cache, the load balancer, the queue, the rate limiter, a small key-value store, the deploy tool, even a
toy container runtime. Standard library for primitives only: sockets, buffers, JSON, TLS. No frameworks,
no AI.

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

1. Claude writes a card in `labs/NN/card.md` describing what's happening and what "fixed" looks
   like in numbers, then changes the traffic. Usually something on the dashboard goes red.
2. I dig in, read, design, build, deploy. If I'm stuck Claude asks questions or points me at things to
   read. It doesn't tell me the answer.
3. When the scenario's panel has been green for 24 hours, Claude tries to break what I built and reviews
   the design.
4. I fix whatever the attack found that the card asked for, write the ADR and the lab log, commit, and
   the next card arrives. Findings outside the card go to `.claude/backlog.md`.

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
- Side quests are fine if they're bounded. A key-value store with a log and a hash index is bounded.
  A relational engine to hold orders is not, so orders stay in Postgres.
- No AI anywhere near `app/`. No completion, no generated code, no "fix this". Docs, books and library
  source are fine. Stack Overflow after I've been stuck for 20 minutes.
- Claude never touches app code. It writes cards, traffic profiles, chaos scripts and reviews, and tells
  me when my fix is a band-aid.
- Every scenario ends with an ADR that includes what I rejected.
- If there's no measurement, it didn't happen.
- A fix that has to be repeated in every caller is in the wrong place.
- Green on the dashboard isn't done. Green for 24 hours plus the ADR is done.

## The store

Products with stock, a cart, checkout, orders. Postgres.

When it gets built: scenario 01 is the HTTP server, a package that accepts connections, parses
requests and hands them to a handler, plus an app of exactly one handler so `/health` answers. The
server knows nothing about routes. Scenario 02 is the store itself: the router, the five endpoints,
the schema, migrations, Postgres. Nothing more is added until a later scenario asks for it.

On top of steady browsing traffic there'll be "drops": a product with limited stock going on sale at a
set time so everyone shows up at once. Both kinds of traffic matter, some problems only show up when
they overlap.

## Scenarios

The order is driven by need. A component shows up in the scenario where its absence starts to hurt,
and only there.

| # | Scenario | What it's about | Built |
|---|---|---|---|
| 01 | The world is already calling | TCP, HTTP/1.1 parsing, keep-alive, timeouts, deploying by hand | HTTP server, a one-handler app |
| 02 | It's supposed to be a store | Project layout, routing, schema, migrations, Postgres | Router, config, migrations |
| 03 | We can't see anything | Request ids, structured logs, percentiles, labels, cardinality, a dashboard of my own | Middleware chain, metrics endpoint, logger |
| 04 | 10× surge at drop time | What saturates first, pool sizing, backpressure, timeouts | Connection pool |
| 05 | The last dependency | Postgres wire protocol, authentication, extended query, decoding | Postgres driver, `pgx` removed |
| 06 | Stock went negative | Transactions, isolation, locking, idempotent checkout | |
| 07 | Thundering herd on the hot product | Hot keys, TTLs, expiry stampedes, what not to cache | In-process cache |
| 08 | One instance isn't enough | A second app box, balancing, health checks, two caches that now disagree | Load balancer v1 |
| 09 | Deploy during a drop | Graceful shutdown, draining, readiness vs liveness, rollback, TLS termination | Deploy tool, load balancer v2 |
| 10 | Backends come and go | A crashed instance kept getting traffic, a new one got none. Heartbeats, TTLs, membership | Service registry |
| 11 | Every instance misses alone | Shared cache, wire protocol, TTL, eviction | Cache server, in memory |
| 12 | The cache node restarted cold | Cold start stampede, append-only log, hash index, fsync, recovery, compaction. Cap doubled | Bitcask-style persistence |
| 13 | The cache node died | Leader and follower, log shipping, catch-up, failover without consensus | KV replication |
| 14 | Payment provider gets slow | Payments arrive. Outbound calls, timeouts, circuit breakers, bulkheads | HTTP client, circuit breaker |
| 15 | Checkout takes too long | 202 and order states, stock reservation and release, acks, retries, dead letters | Job queue, worker |
| 16 | The catalog grew | 200k products. Listing without pagination dies, search arrives, tokenising, inverted index | Pagination, search index |
| 17 | The reporting endpoint | Ops hits sales-by-hour every minute. Statement timeouts, isolating workloads | |
| 18 | Reads drown writes | Streaming replica, read/write split in the pool, replication lag | |
| 19 | Database fails over | Fire drill I run: kill the primary, promote. Reconnect storms, backoff, retry budgets | |
| 20 | Abuse and bots | Rate limiting with counters shared across instances, backpressure, 429 semantics | Rate limiter |
| 21 | Reservations and carts pile up | Expiring reservations from 15, abandoned carts, batch jobs vs live traffic | Job scheduler |
| 22 | What's in a container | Namespaces, cgroups, rootfs, what Docker actually does | Mini container runtime |
| 23 | Move it to Kubernetes | A cluster. What the platform now does that I built: balancer, registry, deploy tool. Keep or drop each | |
| 24 | Pods die, node is full | Claude gets a kubeconfig that can only delete pods. Autoscaling, limits, disruption budgets | |
| 25 | Config and secrets | Rotation without restarts, reload semantics, internal endpoints get secrets | |
| 26 | The warehouse feed | A second writer of stock, from outside, while people buy | |
| 27 | Incident week | Claude gets a chaos user for a week. Run it, write the postmortem | |
| 28 | Wrap up | Finish the lifecycle doc, load report, maybe a blog post | |

### How they chain

Each scenario leaves something the next one needs, or breaks something the previous one built.

- **01 → 02 → 03.** The server exists, so the store can be built on it. The store exists, so there's
  something worth seeing, and a middleware chain finally has things to hold: ids, logs, timings,
  metrics. From 03 on, every scenario is diagnosed on my own numbers next to Claude's.
- **04 → 05 → 06.** The surge shows what saturates first, and connections to Postgres are near the
  top, so the pool gets built. Owning the pool puts me one layer from the wire, so the driver follows
  and `pgx` goes. Owning both is what makes the concurrency bug in 06 fully debuggable.
- **07 → 08.** The drop makes one product a hot key and the cache fixes it, until one box isn't
  enough. A second app box needs a balancer. Now there are two caches, and they disagree about stock.
- **09 → 10.** There's something to deploy to without downtime, so the app learns to shut down
  cleanly, the balancer learns to drain, the deploy tool drives both, and since every request passes
  the balancer anyway, TLS terminates there. Then an instance crashes and the balancer keeps routing
  to it, so membership stops being a static list.
- **11 → 12 → 13.** Each instance misses alone, so the drop stampedes Postgres once per instance. A
  shared cache fixes that and becomes the home for shared state later scenarios need. Then it
  restarts empty and the stampede is back, so it learns to persist. Then it dies and persistence
  isn't enough, so it gets a replica.
- **14 → 15.** Payments arrive, which means an outbound HTTP call, which means an HTTP client. The
  provider is slow, breakers help, but checkout is still synchronous on a slow call, so it moves
  behind a queue, and stock has to be reserved and released instead of just decremented.
- **16 → 19.** The catalog grows and the database becomes the problem from four directions: listing
  and search, a reporting endpoint, read volume, failover.
- **20 → 21.** Bots force rate limiting, and the counters live in the shared cache from 11 because
  there are two instances. Reservations from 15 and abandoned carts need expiring, so a scheduler
  that doesn't fight live traffic.
- **22 → 25.** Build a toy container runtime so Kubernetes isn't magic. Move onto Kubernetes and
  decide, component by component, what the platform now does that I built. Then deal with what it
  does to the app under load, and with config and secrets inside it.
- **26 → 28.** A second writer of stock, an incident with no warning, and the write-up.

Roughly 30 weeks of work if I did one a week. I won't, so it'll take longer.

## Access and chaos

Claude reaches the app only from the outside, as traffic. It never has a shell on an app box. So:

- Anything the outside world can do, Claude does: traffic shapes, bots, a slow payment provider,
  malformed requests, connection floods.
- Anything that needs to happen inside a box is a fire drill. Claude writes the script into
  `world/chaos/`, I run it when I choose. Scenario 19 is this.
- Scenario 24: I give Claude a kubeconfig scoped to deleting pods and nothing else. Writing that role
  is part of the scenario.
- Scenario 27: Claude gets a chaos user on the app boxes for one week, with what it can do written
  down beforehand. Revoked after.

## Who writes where

| Path | Whose | What |
|---|---|---|
| `app/` | me | The store and every component. No AI touches this. |
| `docs/request-lifecycle.md` | me | One request traced end to end, a section per step |
| `labs/NN/adr.md`, `log.md`, `metrics.png` | me | Decision record, lab log, dashboard screenshot |
| `labs/NN/card.md` | Claude | The scenario |
| `labs/_templates/` | Claude | Blank ADR and log |
| `world/` | Claude | Provisioning, dashboards, k6 profiles, chaos scripts, fake payment provider |
| `.claude/` | both | Project context, current state, backlog, Claude's operating rules |
| the READMEs | both | |

Claude's commits are authored as `world (Claude)`, mine as me, so `git log --author` separates the two
sides.

## Infrastructure

DigitalOcean. `world` (2 vCPU, 2 GB) has Prometheus, Grafana, k6 and later the fake payment provider.
Claude sets it up and owns it. `app` (1 vCPU, 1 GB) starts as bare Ubuntu with Postgres and the store,
kept small on purpose so I hit limits early. I deploy to it by hand until a scenario makes that painful.

The app side grows as the scenarios demand it, and that's deliberate: a second app box and somewhere
for the balancer to live in 08, a replica database in 18, a cluster in 23. Each one costs money and
arrives only when the previous shape has actually broken.

## Status

Lives in [`.claude/state.md`](.claude/state.md).
