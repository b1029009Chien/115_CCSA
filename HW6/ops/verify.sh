#!/usr/bin/env bash
set -euo pipefail

# verify.sh
# - Verify the mcapp stack services are running and healthy
# - Poll the /healthz endpoint until success or timeout

HOST=${1:-localhost}
PORT=${2:-80}
TIMEOUT=${TIMEOUT:-30}  # seconds

echo "Checking stack services..."
docker service ls | grep mcapp || true

for svc in mcapp_api mcapp_web mcapp_db; do
  echo "Service status for $svc:" 
  docker service ps --no-trunc "$svc" || true
done

# Poll health endpoint
URL="http://$HOST:$PORT/healthz"

echo "Polling health endpoint $URL for up to $TIMEOUT seconds..."
SECS=0
INTERVAL=2
while [[ $SECS -lt $TIMEOUT ]]; do
  if curl -fsS "$URL" >/dev/null 2>&1; then
    echo "Health endpoint responded successfully."
    curl -sS "$URL" || true
    exit 0
  fi
  sleep $INTERVAL
  SECS=$((SECS + INTERVAL))
  echo "...waiting ($SECS/$TIMEOUT)"
done

echo "Health check failed after $TIMEOUT seconds." >&2
exit 2
