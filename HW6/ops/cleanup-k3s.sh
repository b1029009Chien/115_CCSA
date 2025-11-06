#!/usr/bin/env bash
set -euo pipefail

# cleanup-k3s.sh
# - Remove the application from k3s
# - Optionally uninstall k3s completely

usage() {
  cat <<EOF
Usage: $0 [--uninstall-k3s]

--uninstall-k3s   Remove the application AND uninstall k3s completely
EOF
}

UNINSTALL_K3S=0
if [[ ${1:-} == "--uninstall-k3s" ]]; then
  UNINSTALL_K3S=1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
K3S_DIR="$ROOT_DIR/content/k3s"

if ! command -v k3s &> /dev/null; then
  echo "k3s is not installed. Nothing to clean up."
  exit 0
fi

echo "Removing application from k3s..."

# Delete resources in reverse order
sudo k3s kubectl delete -f "$K3S_DIR/ingress.yaml" --ignore-not-found=true
sudo k3s kubectl delete -f "$K3S_DIR/frontend.yaml" --ignore-not-found=true
sudo k3s kubectl delete -f "$K3S_DIR/backend.yaml" --ignore-not-found=true
sudo k3s kubectl delete -f "$K3S_DIR/database.yaml" --ignore-not-found=true
sudo k3s kubectl delete -f "$K3S_DIR/namespace.yaml" --ignore-not-found=true

echo "Application removed from k3s"

if [[ $UNINSTALL_K3S -eq 1 ]]; then
  echo ""
  echo "Uninstalling k3s..."
  
  if [ -f /usr/local/bin/k3s-uninstall.sh ]; then
    sudo /usr/local/bin/k3s-uninstall.sh
    echo "k3s uninstalled successfully"
  else
    echo "k3s uninstall script not found. k3s may not be properly installed."
  fi
  
  # Clean up kubectl config
  if [ -f ~/.kube/config ]; then
    echo "Removing kubectl config..."
    rm -f ~/.kube/config
  fi
fi

echo "Cleanup complete!"
