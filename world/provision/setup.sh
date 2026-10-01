#!/usr/bin/env bash
# backend-labs: provision the world droplet. Idempotent. Run as root.
set -euo pipefail
REPO=/srv/world/repo
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq git ufw curl gnupg prometheus >/dev/null

mkdir -p /etc/apt/keyrings
curl -fsSL https://apt.grafana.com/gpg.key | gpg --dearmor --yes -o /etc/apt/keyrings/grafana.gpg
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" > /etc/apt/sources.list.d/grafana.list
curl -fsSL https://dl.k6.io/key.gpg | gpg --dearmor --yes -o /etc/apt/keyrings/k6.gpg
echo "deb [signed-by=/etc/apt/keyrings/k6.gpg] https://dl.k6.io/deb stable main" > /etc/apt/sources.list.d/k6.list
apt-get update -qq
apt-get install -y -qq grafana k6 >/dev/null

mkdir -p /srv/world/profiles
if [ -d "$REPO/.git" ]; then git -C "$REPO" pull -q; else git clone -q https://github.com/LazarKap/backend-labs.git "$REPO"; fi

# Prometheus: accept k6 remote write, keep 90 days
sed -i 's|^ARGS=.*|ARGS="--web.enable-remote-write-receiver --storage.tsdb.retention.time=90d"|' /etc/default/prometheus
install -m 644 "$REPO/world/provision/prometheus.yml" /etc/prometheus/prometheus.yml
systemctl enable -q prometheus
systemctl restart prometheus

# Grafana: datasource + dashboards from the repo, admin password generated once
install -m 644 "$REPO/world/provision/grafana-datasource.yml" /etc/grafana/provisioning/datasources/prometheus.yml
install -m 644 "$REPO/world/provision/grafana-dashboards.yml" /etc/grafana/provisioning/dashboards/world.yml
mkdir -p /var/lib/grafana/dashboards
cp "$REPO"/world/dashboards/*.json /var/lib/grafana/dashboards/
chown -R grafana:grafana /var/lib/grafana/dashboards
systemctl enable -q grafana-server
systemctl restart grafana-server
if [ ! -f /root/.grafana-admin ]; then
  PW=$(openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | cut -c1-20)
  echo "$PW" > /root/.grafana-admin; chmod 600 /root/.grafana-admin
  for i in $(seq 1 20); do curl -fs localhost:3000/api/health >/dev/null && break; sleep 2; done
  grafana-cli admin reset-admin-password "$PW" >/dev/null
fi

# k6 runner: runs whatever /srv/world/profiles/current.js points at, forever
install -m 644 "$REPO/world/provision/k6-profile.service" /etc/systemd/system/k6-profile.service
[ -f /etc/world.env ] || install -m 600 "$REPO/world/provision/world.env.example" /etc/world.env
systemctl daemon-reload
systemctl enable -q k6-profile

[ -f /srv/world/state.json ] || echo '{"scenario":null,"profile":null,"since":null}' > /srv/world/state.json

ufw allow 22/tcp >/dev/null; ufw allow 3000/tcp >/dev/null; ufw --force enable >/dev/null
echo "world provisioned. grafana admin password: /root/.grafana-admin"
