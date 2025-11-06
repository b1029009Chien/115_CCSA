#!/usr/bin/env bash
set -euo pipefail

# deploy.sh
# - Deploy the swarm stack using HW5/content/swarm/stack.yaml
# - Optional: pass BUILD=1 to build and push images before deploy (assumes Docker Hub credentials configured)

usage() {
  cat <<EOF
Usage: $0 [--build]

--build   Build and push backend/frontend images before deploying. Requires DOCKER_USERNAME set or already logged in.
EOF
}

BUILD=0
if [[ ${1:-} == "--build" ]]; then
  BUILD=1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SWARM_DIR="$ROOT_DIR/content/swarm"
FRONTEND_DIR="$ROOT_DIR/content/frontend"
BACKEND_DIR="$ROOT_DIR/content/backend"

if [[ $BUILD -eq 1 ]]; then
  echo "Building and pushing images..."
  (cd "$BACKEND_DIR" && docker build -t chien314832001/hw5_api:latest . && docker push chien314832001/hw5_api:latest)
  (cd "$FRONTEND_DIR" && docker build -t chien314832001/hw5_web:latest . && docker push chien314832001/hw5_web:latest)
fi

echo "Deploying stack from $SWARM_DIR/stack.yaml"
docker stack deploy -c "$SWARM_DIR/stack.yaml" mcapp

echo "Deploy initiated. Use 'docker service ls' and 'docker service ps <service>' to monitor progress."
