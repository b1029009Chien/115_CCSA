#!/usr/bin/env bash
set -euo pipefail

# cleanup.sh
# - Remove the mcapp stack and optionally remove named volume and network

REMOVE_VOLUMES=0
if [[ ${1:-} == "--remove-volumes" ]]; then
  REMOVE_VOLUMES=1
fi

echo "Removing stack 'mcapp'..."
docker stack rm mcapp || true

# Wait a bit for services to be removed
sleep 3

if [[ $REMOVE_VOLUMES -eq 1 ]]; then
  echo "Removing named volume 'dbdata' if present (may be local to a node)..."
  if docker volume ls --format '{{.Name}}' | grep -wq dbdata; then
    docker volume rm dbdata || true
  fi
  if docker volume ls --format '{{.Name}}' | grep -wq mcapp_dbdata; then
    docker volume rm mcapp_dbdata || true
  fi
  echo "Note: On multi-node clusters, volumes are local to the node where created."
fi

# Optionally remove the overlay network if no longer used
if docker network ls --format '{{.Name}}' | grep -wq appnet; then
  echo "Removing overlay network 'appnet'..."
  docker network rm appnet || true
fi

echo "Cleanup complete."
