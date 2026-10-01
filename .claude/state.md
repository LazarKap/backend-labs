# State

**Scenario:** 01 — The world is already calling. **Open since 2026-10-01 12:09 UTC.**
**Status:** red. Traffic is hitting the `app` droplet on 8080 and getting connection refused.
**Updated:** 2026-10-01

## Where things stand

- `world`: provisioned, profile `01/health.js` running as `k6-profile`, "world · black box" dashboard
  live. Both SLO stats red.
- `app`: exists, bare Ubuntu 24.04, only sshd listening. Lazar's box from here on.
- Card: `labs/01/card.md`. Soft cap: two weeks, so around 2026-10-15.

## Next

Lazar: read the card, write the HTTP server and the one-handler app, deploy under systemd, watch the
panel turn green. Then 24 h green, Claude's attack, ADR, log, screenshot, lifecycle section.

Claude: nothing until asked for numbers or until the panel has been green 24 h.

## Blockers

None.
