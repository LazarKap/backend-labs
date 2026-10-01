# 01 — The world is already calling

## Situation

Traffic has been hitting `http://<app-ip>:8080/health` every few seconds since this morning. Connection
refused, every time. The dashboard on `world` has one panel and it's red.

There's no app. There's no HTTP server. There's a bare Ubuntu box with your SSH key on it. Make the
panel green, with a server you wrote, not one you imported.

Two things get built this scenario and they are not the same thing. The HTTP server: accepts
connections, parses requests, hands each one to whatever is plugged in, writes the response back. It
knows nothing about `/health`. And the app: this week it is one handler, `/health` says ok, anything
else is a 404. Next scenario the app grows a router and a database and the server doesn't change.

## Numbers

Current traffic profile (`world/profiles/week-01/health.js`):

| Request | Rate | Target |
|---|---|---|
| `GET /health` | every 5 s, plus a steady 20 req/s from 10 concurrent clients using keep-alive | 200 within 50 ms, body `ok` |
| anything else | occasional | 404, connection stays usable |

Error budget: 0.1% of requests may fail (non-200 on `/health`, connection error, or timeout).

## Constraints

- Go. `net` for the TCP listener, `bufio`/`io` for reading, nothing from `net/http`. No third-party
  packages at all this scenario.
- HTTP/1.1. Requests arrive with and without `Connection: keep-alive`. Some have a body with a
  `Content-Length`. Chunked request bodies can be rejected with a 411, that's fine for now.
- The server is a package the app imports, not a program that happens to contain the app. The
  boundary between them, what a handler receives and what it returns, is yours to design and is the
  first thing the ADR has to cover.
- Timeouts are yours to choose and justify: how long a client may take to send a request line, how
  long an idle keep-alive connection lives, how many connections you accept at once.
- Deploy by hand: build locally, copy the binary, run it under systemd so it survives a reboot. No
  containers, no CI, no Makefile that hides what happens.
- Plain HTTP on 8080. TLS comes later.

## Done when

- The "01 · exists" panel on `world`'s Grafana is green for 24 hours: every `/health` within target,
  error budget not exhausted.
- `go test ./...` and `go vet ./...` are clean. There are tests for the parser: request line, headers,
  `Content-Length` bodies, a request split across two reads, a request with garbage in it.
- `app/README.md` says how to build, run, and deploy.
- `adr.md` covers at least: the boundary between server and handler, how connections are accepted and
  handed off, how a request is parsed, the timeouts you chose and why, what happens when the box runs
  out of file descriptors.
- `docs/request-lifecycle.md` has the HTTP server section filled in.

## The operator will

- Run `health.js` from `world` continuously from the moment the scenario opens.
- On verification day, against the live server: a request line with no HTTP version, a header line
  with no colon, a header 64 KB long, a `Content-Length` larger than the body actually sent, a
  `Content-Length` smaller than the body, 500 connections opened at once that each send one byte
  and then wait, a client that sends a valid request and never reads the response, and a `GET /health`
  pipelined five times on one connection. Record what the server does with each. The `/health` panel
  should stay green throughout.
