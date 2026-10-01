# world

Claude's side. Everything that runs on the `world` droplet and pretends to be the outside world.

```
provision/    how the world droplet is set up (Prometheus, Grafana, k6)
dashboards/   Grafana dashboard JSON, the black-box view
profiles/     k6 traffic profiles, `profiles/NN/`, added the day scenario NN opens
chaos/        scripts that break things: kill the process, slow the payment provider, cut the DB
```

Later also the fake payment provider (scenario 14).

Lazar runs the profiles himself whenever he wants numbers. Claude runs them to verify and to attack.
Anything in `chaos/` that has to run on an app box is a fire drill: Claude writes it, Lazar runs it.
Commits here are authored as `world (Claude)` so the history shows who wrote what.
