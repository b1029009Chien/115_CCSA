#!/usr/bin/env bash
set -euo pipefail

# deploy-k3s-safe.sh
# Safe deployment script with proper waiting

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
K3S_DIR="$ROOT_DIR/content/k3s"

echo "=== k3s Safe Deployment Script ==="
echo ""

# Check if k3s is installed
if ! command -v k3s &> /dev/null; then
  echo "❌ k3s is not installed. Please run init-k3s.sh first" >&2
  exit 1
fi

# Wait for k3s to be ready
echo "⏳ Waiting for k3s to be ready..."
timeout=60
counter=0
while ! sudo k3s kubectl get nodes &> /dev/null; do
  if [ $counter -ge $timeout ]; then
    echo "❌ Timeout waiting for k3s" >&2
    echo "Try running: sudo systemctl restart k3s"
    exit 1
  fi
  sleep 2
  counter=$((counter + 2))
  printf "."
done
echo ""
echo "✓ k3s is responding"

# Wait for system pods to be ready
echo ""
echo "⏳ Waiting for k3s system components..."
sudo k3s kubectl wait --for=condition=Ready node --all --timeout=60s 2>/dev/null || true
sleep 5

# Check if kube-system pods are running
echo "⏳ Waiting for core services..."
for i in {1..30}; do
  READY=$(sudo k3s kubectl get pods -n kube-system --no-headers 2>/dev/null | grep -c "Running" || echo "0")
  if [ "$READY" -ge 3 ]; then
    echo "✓ Core services ready"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "⚠️  Core services still starting, continuing anyway..."
  fi
  sleep 2
done

sleep 5

echo ""
echo "=== Deploying application to k3s ==="
echo "Directory: $K3S_DIR"
echo ""

# Deploy namespace
echo "📦 Step 1/5: Creating namespace..."
if sudo k3s kubectl apply -f "$K3S_DIR/namespace.yaml"; then
  echo "✓ Namespace created"
else
  echo "⚠️  Namespace already exists or failed to create"
fi
sleep 3

# Deploy database
echo ""
echo "📦 Step 2/5: Deploying database..."
if sudo k3s kubectl apply -f "$K3S_DIR/database.yaml"; then
  echo "✓ Database resources created"
  echo "⏳ Waiting for database pod to start..."
  sudo k3s kubectl wait --for=condition=Ready pod -n mcapp -l app=db --timeout=120s 2>/dev/null || echo "⚠️  Database still starting..."
else
  echo "❌ Failed to deploy database"
  exit 1
fi
sleep 5

# Deploy backend
echo ""
echo "📦 Step 3/5: Deploying backend API..."
if sudo k3s kubectl apply -f "$K3S_DIR/backend.yaml"; then
  echo "✓ Backend resources created"
  echo "⏳ Waiting for backend pods to start..."
  sudo k3s kubectl wait --for=condition=Ready pod -n mcapp -l app=api --timeout=120s 2>/dev/null || echo "⚠️  Backend still starting..."
else
  echo "❌ Failed to deploy backend"
  exit 1
fi
sleep 5

# Deploy frontend
echo ""
echo "📦 Step 4/5: Deploying frontend..."
if sudo k3s kubectl apply -f "$K3S_DIR/frontend.yaml"; then
  echo "✓ Frontend resources created"
  echo "⏳ Waiting for frontend pod to start..."
  sudo k3s kubectl wait --for=condition=Ready pod -n mcapp -l app=web --timeout=120s 2>/dev/null || echo "⚠️  Frontend still starting..."
else
  echo "❌ Failed to deploy frontend"
  exit 1
fi
sleep 3

# Deploy ingress
echo ""
echo "📦 Step 5/5: Deploying ingress..."
if sudo k3s kubectl apply -f "$K3S_DIR/ingress.yaml"; then
  echo "✓ Ingress created"
else
  echo "⚠️  Ingress already exists or failed to create"
fi

echo ""
echo "=== Deployment Status ==="
echo ""
sudo k3s kubectl get all -n mcapp

echo ""
echo "=== Access Information ==="
echo ""
WSL_IP=$(hostname -I | awk '{print $1}')
echo "🌐 Application URLs:"
echo "   - http://localhost:30080"
echo "   - http://$WSL_IP:30080"
echo ""
echo "📊 Monitor deployment:"
echo "   sudo k3s kubectl get pods -n mcapp -w"
echo ""
echo "📝 View logs:"
echo "   sudo k3s kubectl logs -n mcapp -l app=api"
echo "   sudo k3s kubectl logs -n mcapp -l app=web"
echo "   sudo k3s kubectl logs -n mcapp -l app=db"
echo ""
echo "✅ Deployment complete!"
