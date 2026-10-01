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

## What's running and how to reach it

Provisioned 2026-10-01 by `provision/setup.sh`. Re-running the script is safe; it only changes what
drifted. Addresses and the Grafana password are in Lazar's private access notes, not here.

| Thing | Where | Port | Notes |
|---|---|---|---|
| Grafana | `http://<world-ip>:3000` | 3000, public | User `admin`. Dashboard "world · black box" is provisioned from `dashboards/`, read-only in the UI. Edit the JSON in the repo, pull on the box, it reloads within 30 s. |
| Prometheus | on the box only | 9090, localhost | Remote-write receiver on, 90-day retention. `curl localhost:9090/api/v1/query --data-urlencode 'query=...'` for ad hoc questions. |
| k6 runner | `k6-profile.service` | | Runs `/srv/world/profiles/current.js` forever, restarts on exit. Target comes from `/etc/world.env` (`APP_HOST`). |
| Repo checkout | `/srv/world/repo` | | `git -C /srv/world/repo pull` to get new profiles and dashboards. |
| State | `/srv/world/state.json` | | Which scenario and profile are active and since when. Claude updates it. |
| Firewall | `ufw` | | 22 and 3000 open. Everything else closed. |

### Switching the profile

```
ln -sfn /srv/world/repo/world/profiles/01/health.js /srv/world/profiles/current.js
systemctl restart k6-profile
```

### Watching it

```
systemctl status k6-profile              # is it running, since when
journalctl -u k6-profile -f              # every failed request as it happens, with the error
journalctl -u k6-profile --since -10m    # the last ten minutes
systemctl stop k6-profile                # silence, e.g. while you redeploy on purpose
```

### How the numbers flow

k6 sends requests to the app and pushes what it saw (status, duration, errors, dropped iterations)
into Prometheus every few seconds via remote write. Grafana reads Prometheus. From scenario 03 on,
Prometheus also scrapes the app's own metrics endpoint over the private network, so white-box and
black-box sit on the same dashboards.

### k6 error codes you'll see in `error_code`

| Code | Means |
|---|---|
| 1050 | Request timeout, the server accepted but never finished answering within 2 s |
| 1213 | Dial timeout, no TCP connection could be made |
| 1212 | Connection refused, nothing is listening |
| 1211 | Connection reset by the server |
| 1000 | Generic, read the log line |
