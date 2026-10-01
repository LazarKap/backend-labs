# Project context

Shared between Lazar's two machines through this repo. Pull before starting, push when stopping.

## What this is

Lazar's side project to build the whole backend stack by hand in Go and run it under constant load.
He runs production systems on top of all of this at work; this is depth and fun, not remediation.
Portfolio value is a side effect: the ADRs, the lifecycle doc, and a verifiable "no AI in app/" history.

## Decisions, and why

- **Go.** Single static binary, the Kubernetes world is Go, destination is platform work.
- **No `net/http`.** The HTTP server is built on raw TCP. "On my own" means every component, including
  the server, router, pool, driver, cache, LB, queue, KV store, rate limiter, deploy tool, container
  runtime. Stdlib stays for primitives only: `net`, `bufio`, `io`, `os`, `sync`, `encoding/json`,
  `crypto/tls`.
- **`pgx` until scenario 05**, then his own wire-protocol driver replaces it. Zero third-party deps
  after that.
- **Not built:** TLS, DNS, TCP, Kubernetes, a relational engine for orders, and the measuring stick
  (Prometheus, Grafana, k6 on `world`). The last one has to stay independent or the numbers are
  meaningless.
- **Bitcask-style KV store is in** (scenario 11, big one). Backs the cache server. Never holds orders.
- **Store domain, not pure flash sale**: steady browsing plus drops, because some failures only appear
  when two traffic kinds overlap.
- **Scenario-driven, no schedule.** Work hours and evenings as time allows. Two-week soft cap is the
  only clock.
- **Black-box vs white-box split.** Claude owns what the outside sees (client-side latency, status
  codes, rate) on `world`. Lazar owns everything the app knows about itself. Realistic: synthetic
  monitoring vs app metrics.
- **Two new droplets**, never Emberhollow (it has real users and would pollute every number).
- **One repo, two authors.** Claude commits as `world (Claude)`, Lazar as himself.
- **History was squashed once** on 2026-10-01 at Lazar's request before any app code existed. Not
  again.

## Infrastructure, by name only

- `world` droplet: 2 vCPU / 2 GB. Prometheus, Grafana, k6, later the fake payment provider. Claude
  sets it up and has root.
- `app` droplet: 1 vCPU / 1 GB, bare Ubuntu, Postgres, the store. Lazar's. Claude never SSHes in.
- Addresses, keys, logins: Lazar's private notes.

## Where things are written down

- Program, rules, scenario table, chain: `README.md`.
- Card format and done criteria: `labs/README.md`.
- Current scenario and status: `.claude/state.md`.
- Deferred findings: `.claude/backlog.md`.
- Claude's rules: `.claude/operator.md`.
