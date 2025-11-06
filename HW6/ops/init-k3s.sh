#!/usr/bin/env bash
set -euo pipefail

# init-k3s.sh
# - Install k3s if not already installed
# - Configure k3s to be accessible

usage() {
  cat <<EOF
Usage: $0

Install and initialize k3s for the application.
EOF
}

echo "Checking if k3s is installed..."

if ! command -v k3s &> /dev/null; then
  echo "k3s not found. Installing k3s..."
  
  # Install k3s
  curl -sfL https://get.k3s.io | sh -
  
  echo "k3s installed successfully"
else
  echo "k3s is already installed"
fi

# Wait for k3s to be ready
echo "Waiting for k3s to be ready..."
timeout=60
counter=0
while ! sudo k3s kubectl get nodes &> /dev/null; do
  if [ $counter -ge $timeout ]; then
    echo "Timeout waiting for k3s to be ready" >&2
    exit 1
  fi
  sleep 2
  counter=$((counter + 2))
  echo "Waiting... ($counter/$timeout seconds)"
done

echo "k3s is ready!"

# Configure kubectl access for current user
if [ ! -f ~/.kube/config ]; then
  echo "Setting up kubectl configuration..."
  mkdir -p ~/.kube
  sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
  sudo chown $(id -u):$(id -g) ~/.kube/config
  chmod 600 ~/.kube/config
fi

echo "Verifying k3s installation..."
sudo k3s kubectl get nodes
sudo k3s kubectl version --short

echo ""
echo "k3s initialization complete!"
echo "You can now use 'kubectl' or 'k3s kubectl' to interact with the cluster"
