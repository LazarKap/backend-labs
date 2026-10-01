# One request, end to end

What happens to `POST /checkout` between the browser and Postgres, through code I wrote. One section per
step. A step gets filled in when the scenario that builds it closes. Until then it just says which
scenario.

## Map

| Step | Built in |
|---|---|
| DNS resolves `app` | not built, by decision |
| TCP connect, TLS handshake | TCP is the OS. TLS is `crypto/tls` at the load balancer, 10 |
| Load balancer picks a backend from the registry | 08, 09, 10 |
| HTTP server accepts the connection, parses the request | 01 |
| Rate limiter admits or rejects | 20 |
| Router matches the route | 02 |
| Middleware: request id, logging, timeout, metrics | 03 |
| Handler validates the body | 02 |
| Cache lookup for the product | 07, then 11, 12, 13 |
| Connection pool hands out a connection | 04 |
| Driver speaks the Postgres protocol | 05 |
| Transaction: check stock, decrement, insert order | 02, then 06 |
| Outbound call to the payment provider | 14 |
| Job enqueued for payment | 15 |
| Response written, metrics recorded | 01, 03 |
| Where the process runs: systemd, then a container, then a pod | 01, 22, 23 |

## Steps

Each step, once built: what component handles it, link to the code, what it does, why it's shaped that
way, and what I'd change at 10× the load.

### DNS

Not built. A domain pointed at the `app` droplet. Nothing to learn here that a scenario would teach.

### TCP and TLS

TCP is the `net` package, the OS does the work. TLS is `crypto/tls` with a Let's Encrypt cert,
terminated at the load balancer from scenario 10. Writing TLS is cryptography, not backend engineering.

### Load balancer and registry

Scenarios 08, 09 and 10.

### HTTP server

Scenario 01.

### Rate limiter

Scenario 20.

### Router

Scenario 02.

### Middleware

Scenario 03.

### Handler and validation

Scenario 02.

### Cache

Scenario 07, then 11 when it moves out of process, 12 when it persists, 13 when it gets a replica.

### Connection pool

Scenario 04.

### Driver

Scenario 05.

### Transaction

Scenario 02, revisited in 06.

### Outbound call

Scenario 14.

### Queue

Scenario 15.

### Response and metrics

Scenarios 01 and 03.

### Where the process runs

Scenario 01 under systemd, 22 inside a container I built, 23 as a pod.
