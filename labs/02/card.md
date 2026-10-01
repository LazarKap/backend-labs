# 02 — It's supposed to be a store

## Situation

`/health` is green. Good. This morning the traffic changed: people are browsing products, putting
things in a cart, checking out, and looking at their orders. Your server answers 404 to all of it. Five
new panels on the dashboard, all red.

Nobody is going to stop the traffic while you build. Make them green.

## Numbers

Current traffic profile (`world/profiles/02/steady.js`):

| Endpoint | Rate | Target |
|---|---|---|
| `GET /health` | every 5 s | 200 within 100 ms |
| `GET /products` | 3 req/s | p99 < 300 ms |
| `GET /products/{id}` | 2 req/s | p99 < 300 ms |
| `POST /cart/items` | 0.5 req/s | p99 < 300 ms |
| `POST /checkout` | 0.3 req/s | p99 < 500 ms |
| `GET /orders` | 0.5 req/s | p99 < 300 ms |

Error budget across all endpoints: 0.1% of requests may fail (5xx or connection error).

Catalogue: 20 products. One of them, `drop-001`, has stock 100 and is not special yet.

## Constraints

- Your HTTP server from scenario 01, plus the standard library for primitives, plus `pgx`. Nothing
  else. Routing and middleware are yours to write.
- Exactly five endpoints plus `/health`. The user is the `X-User-ID` header. No auth, no images, no
  search, no categories, no admin, no pagination.
- Checkout buys whatever is in the cart, decrements stock, creates an order, empties the cart. Stock is
  checked. Nothing is said here about what happens when two people check out at the same moment.
- Postgres runs on the `app` droplet. Migrations are plain SQL files applied by your own code or script.
- The listen address and the Postgres connection details come from outside the binary. How is your call.
- Deploy by hand: build locally, copy the binary, run it under systemd. No containers, no CI, no Make
  targets that hide what happens.
- `/health` returns 200 only when the app can actually serve a request, which includes reaching Postgres.

## Done when

- The SLO panel "02 · store" on `world`'s Grafana is green for 24 hours: every row in the table above
  within target, error budget not exhausted.
- `go test ./...` and `go vet ./...` are clean.
- `app/README.md` says how to build, migrate, run, and deploy, and a stranger could do it.
- `adr.md` covers at least: project layout, how routing and middleware are done, how migrations run, why
  the schema is shaped as it is.
- `docs/request-lifecycle.md` has the router, middleware, handler and transaction sections filled in.

## Claude will

- Run `steady.js` from `world` continuously from the moment the scenario opens.
- On verification day: send malformed JSON, unknown product ids, negative quantities, a checkout with an
  empty cart, a checkout for more stock than exists, a 10 MB body, and a client that opens a connection
  and never sends. Record what the app does with each. None of these should take anything else down.
