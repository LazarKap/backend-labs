# One request, end to end

What happens to `POST /checkout` between the browser and Postgres, through code I wrote. One section per
step. A step gets filled in when the scenario that builds it closes. Until then it just says which
scenario.

## Map

| Step | Built in |
|---|---|
| DNS resolves `app` | not built, by decision |
| TCP connect, TLS handshake | `crypto/tls`, not built, by decision |
| Load balancer picks a backend from the registry | 08, 09, 10 |
| HTTP server accepts the connection, parses the request | 01 |
| Rate limiter admits or rejects | 20 |
| Router matches the route | 02 |
| Middleware: request id, logging, timeout, metrics | 02, 03 |
| Handler validates the body | 02 |
| Cache lookup for the product | 07, then 12, 13 |
| Connection pool hands out a connection | 04 |
| Driver speaks the Postgres protocol | 05 |
| Transaction: check stock, decrement, insert order | 02, then 06 |
| Job enqueued for payment | 15 |
| Response written, metrics recorded | 01, 03 |

## Steps

Each step, once built: what component handles it, link to the code, what it does, why it's shaped that
way, and what I'd change at 10× the load.

### DNS

Not built. A domain pointed at the `app` droplet. Nothing to learn here that a scenario would teach.

### TCP and TLS

TCP is the `net` package, the OS does the work. TLS is `crypto/tls` with a Let's Encrypt cert. Writing
TLS is cryptography, not backend engineering.

### Load balancer and registry

Scenarios 08, 09 and 10.

### HTTP server

Scenario 01. Mine, on a raw `net` TCP listener. Accepts connections, reads bytes, parses the request
line and headers, handles `Content-Length` and keep-alive, writes responses, enforces read and idle
timeouts so a slow client can't hold a connection forever. HTTP/1.1 only, no HTTP/2. TLS is
`crypto/tls` wrapped around the listener.

### Rate limiter

Scenario 20.

### Router

Scenario 02.

### Middleware

Scenarios 02 and 03.

### Handler and validation

Scenario 02.

### Cache

Scenario 07, then 12 when it moves out of process, 13 when it gets a replica.

### Connection pool

Scenario 04.

### Driver

Scenario 05.

### Transaction

Scenario 02, revisited in 06.

### Queue

Scenario 15.

### Response and metrics

Scenarios 01 and 03.
