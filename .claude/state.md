# State

**Scenario:** none open yet. `world` is provisioned, `app` does not exist.
**Status:** blocked on the DigitalOcean droplet limit (3, all used). Lazar is raising it.
**Updated:** 2026-10-01

## Done

- `world` droplet created, provisioned: Prometheus (remote write on), Grafana + "world · black box"
  dashboard, k6 2.3, runner unit installed and enabled, firewall. Pipeline smoke-tested end to end.
- `world/README.md` "What's running", `world/cheatsheet.md`.
- Private access notes written (IPs, Grafana login) in Lazar's context folder.

## Next

1. Lazar raises the droplet limit (ask for 6). Claude creates `app` (`s-1vcpu-1gb`, FRA1, both keys).
2. Claude sets `APP_HOST` in `/etc/world.env`, links profile 01 as `current.js`, starts
   `k6-profile`, updates `/srv/world/state.json`. The "01 · exists" panel goes red.
3. Scenario 01 is open. Lazar reads `labs/01/card.md`.

## Blockers

Droplet limit.
