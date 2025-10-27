#!/usr/bin/env bash
set -euo pipefail

# init-swarm.sh
# - initialize Docker Swarm (if not already active)
# - create overlay network `appnet` if missing
# - add node label role=db to this node if run on manager (optional)

usage() {
  cat <<EOF
Usage: $0 [--label-db]

--label-db    If provided and this node is a manager, add label node.labels.role=db to this node.

Run this on a manager node (some operations require manager privileges).
EOF
}

LABEL_DB=0
if [[ ${1:-} == "--label-db" ]]; then
  LABEL_DB=1
fi

echo "Checking Docker..."
docker version >/dev/null 2>&1 || { echo "Docker is not available or not running" >&2; exit 1; }

SWARM_ACTIVE=$(docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null || true)
if [[ "$SWARM_ACTIVE" != "active" ]]; then
  echo "Swarm not active. Initializing swarm..."
  # Try to choose an advertise address; fall back to hostname if missing
  ADDR=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
  if [[ -z "$ADDR" ]]; then
    docker swarm init || true
  else
    docker swarm init --advertise-addr "$ADDR" || true
  fi
else
  echo "Swarm already active (state=${SWARM_ACTIVE})."
fi

# Create overlay network if missing
if ! docker network ls --format '{{.Name}}' | grep -wq appnet; then
  echo "Creating overlay network 'appnet'..."
  docker network create -d overlay appnet || true
else
  echo "Overlay network 'appnet' already exists."
fi

# Optionally label this node as db (requires manager)
if [[ $LABEL_DB -eq 1 ]]; then
  if docker node ls >/dev/null 2>&1; then
    NODE_ID=$(docker info --format '{{.Swarm.NodeID}}')
    if [[ -z "$NODE_ID" ]]; then
      echo "Could not determine node ID" >&2
      exit 1
    fi
    echo "Labeling current node with node.labels.role=db"
    docker node update --label-add role=db "$NODE_ID"
    echo "Label added. Use 'docker node inspect self' or 'docker node ls' to verify."
  else
    echo "This command must be run on a swarm manager to label nodes." >&2
    exit 1
  fi
fi

echo "init-swarm completed. Next: build images (if needed) and run deploy.sh to deploy the stack."
