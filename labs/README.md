# Labs

One folder per scenario. The operator writes `card.md`. I write everything else.

## Card format

1. **Situation.** What's happening, told like a message from a colleague, not a spec.
2. **Numbers.** Current load, targets, limits. Concrete, so "solved" is measurable on the dashboard.
3. **Constraints.** What I'm not allowed to do this scenario, so the easy escape is closed.
4. **Done when.** The SLO panel definition and anything else the operator checks.
5. **The operator will.** The traffic profile and the attacks, so nothing is a surprise except scenario 22.

Cards never contain the solution or name the pattern. Finding the pattern is the research.

## My deliverables per scenario

- `adr.md` from `_templates/adr.md`: the decision, alternatives rejected, consequences accepted.
- `log.md` from `_templates/log.md`: observed, tried, result, operator findings, would do differently.
- `metrics.png`: one dashboard screenshot, before and after under load.
- One new step in `docs/request-lifecycle.md` if the scenario added or changed a component.

## Done means

SLO panel green for 24 hours under the active profile, the ADR committed, and the operator's attack
found nothing the card already asked for. Findings outside the card go to the next scenario or the
backlog, not into a late-night fix.
