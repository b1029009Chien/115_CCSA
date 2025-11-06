#!/usr/bin/env bash
set -euo pipefail

# deploy-k3s.sh
# - Deploy the application to k3s using the manifests in content/k3s/
# - Optional: pass --build to build and push images before deploy

usage() {
  cat <<EOF
Usage: $0 [--build]

--build   Build and push backend/frontend images before deploying.
          Requires DOCKER_USERNAME set or already logged in.
EOF
}

BUILD=0
if [[ ${1:-} == "--build" ]]; then
  BUILD=1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
K3S_DIR="$ROOT_DIR/content/k3s"
FRONTEND_DIR="$ROOT_DIR/content/frontend"
BACKEND_DIR="$ROOT_DIR/content/backend"

# Check if k3s is running
if ! command -v k3s &> /dev/null; then
  echo "k3s is not installed. Please run ./ops/init-k3s.sh first" >&2
  exit 1
fi

if [[ $BUILD -eq 1 ]]; then
  echo "Building and pushing images..."
  (cd "$BACKEND_DIR" && docker build -t chien314832001/hw5_api:latest . && docker push chien314832001/hw5_api:latest)
  (cd "$FRONTEND_DIR" && docker build -t chien314832001/hw5_web:latest . && docker push chien314832001/hw5_web:latest)
fi

echo "Deploying application to k3s from $K3S_DIR"

# Apply manifests
sudo k3s kubectl apply -f "$K3S_DIR/namespace.yaml"
sudo k3s kubectl apply -f "$K3S_DIR/database.yaml"
sudo k3s kubectl apply -f "$K3S_DIR/backend.yaml"
sudo k3s kubectl apply -f "$K3S_DIR/frontend.yaml"
sudo k3s kubectl apply -f "$K3S_DIR/ingress.yaml"

echo ""
echo "Deployment initiated!"
echo ""
echo "Use the following commands to monitor deployment:"
echo "  sudo k3s kubectl get pods -n mcapp"
echo "  sudo k3s kubectl get services -n mcapp"
echo "  sudo k3s kubectl get deployments -n mcapp"
echo ""
echo "To view logs:"
echo "  sudo k3s kubectl logs -n mcapp -l app=api"
echo "  sudo k3s kubectl logs -n mcapp -l app=web"
echo "  sudo k3s kubectl logs -n mcapp -l app=db"
echo ""
echo "Access the application at: http://localhost:30080"
