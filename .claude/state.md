# State

**Scenario:** none open. Planning complete.
**Status:** waiting on droplets.
**Updated:** 2026-10-01

## Next

1. Lazar creates the `world` and `app` droplets on DigitalOcean and gives Claude root on `world`.
2. Claude provisions `world`: Prometheus, Grafana, k6, `world/profiles/01/health.js`, the "01 · exists"
   panel, points traffic at the `app` IP.
3. Scenario 01 opens the moment the panel is red.

## Blockers

None.
