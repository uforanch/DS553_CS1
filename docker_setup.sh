#!/bin/bash
# Script equivalent of docker-compose.yml
set -e

cd "$(dirname "$0")"

# Load NGROK_TOKEN (compose reads it from the shell env or .env)
if [ -f .env ]; then
    source .env
fi
if [ -z "$NGROK_TOKEN" ]; then
    echo "NGROK_TOKEN is not set (export it or put NGROK_TOKEN=... in .env)" >&2
    exit 1
fi

NETWORK=appnet
NGROK_URL=https://exorcism-refill-sincerity.ngrok-free.dev

# Remove old containers so the script can be re-run
docker rm -f group2_killswitch_app spy prometheus grafana ngrok 2>/dev/null || true

# Network and volume (create only if missing)
docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK"
docker volume inspect prometheus-volume >/dev/null 2>&1 || docker volume create prometheus-volume

# Build images (compose's "build:" entries)
docker build -t group2_killswitch_app .
docker build -t spy spy/
docker build -t prometheus Prometheus/
docker build -t grafana Grafana/

# app
docker run -d --name group2_killswitch_app \
    --network "$NETWORK" --network-alias group2_killswitch_app \
    -p 1800:22 -p 1801:7860 -p 1802:9100 -p 1803:8000 \
    --restart unless-stopped \
    group2_killswitch_app

# spy
docker run -d --name group2_spy  \
    --network "$NETWORK" \
    -p 1804:22 \
    --restart unless-stopped \
    spy

# prometheus
docker run -d --name group2_prometheus  \
    --network "$NETWORK" \
    -v prometheus-volume:/prometheus \
    -v "$(pwd)/Prometheus/prometheus.yml:/etc/prometheus/prometheus.yml" \
    -p 1805:22 -p 1806:9090 \
    --restart unless-stopped \
    prometheus

# grafana
docker run -d --name group2_grafana  \
    --network "$NETWORK"  \
    -e GF_SECURITY_ADMIN_USER=admin \
    -e GF_SECURITY_ADMIN_PASSWORD=admin \
    -p 1807:22 -p 1808:3000 \
    --restart unless-stopped \
    grafana

# ngrok: tunnels to the app over the docker network.
# "app" was the compose service name; with plain docker run we use the
# container name/alias instead, so the target is group2_killswitch_app:7860.
# Everything after the image name is the ngrok command (compose's "command:").
docker run -d --name group2_ngrok \
    --network "$NETWORK" \
    -e NGROK_AUTHTOKEN="$NGROK_TOKEN" \
    -p 1809:4040 \
    --restart unless-stopped \
    ngrok/ngrok:latest \
    http group2_killswitch_app:7860 --url "$NGROK_URL"

echo "All containers started."
