# State

**Scenario:** none open. Planning complete.
**Status:** waiting on droplets.
**Updated:** 2026-10-01

## Next

1. Lazar creates the `world` and `app` droplets on DigitalOcean and gives Claude root on `world`.
2. Claude provisions `world`: Prometheus, Grafana, k6, `world/profiles/01/health.js`, the "01 · exists"
   panel, points traffic at the `app` IP.
3. Claude documents it: `world/README.md` gets "What's running and how to reach it" (services, ports,
   Grafana access, k6 runner logs, where profiles and dashboards live, restart/stop) and
   `world/cheatsheet.md` (server-side commands for watching failures on `world` and on `app`).
   Secrets and IPs go to Lazar's private access notes, the README points there.
4. Scenario 01 opens the moment the panel is red.

## Blockers

None.
