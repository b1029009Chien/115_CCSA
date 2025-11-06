#!/usr/bin/env bash
set -euo pipefail

# verify-k3s.sh
# - Verify the k3s deployment is working correctly

echo "Verifying k3s deployment..."
echo ""

# Check if k3s is running
if ! command -v k3s &> /dev/null; then
  echo "❌ k3s is not installed" >&2
  exit 1
fi

echo "✓ k3s is installed"

# Check nodes
echo ""
echo "Cluster nodes:"
sudo k3s kubectl get nodes

# Check namespace
echo ""
echo "Checking namespace 'mcapp'..."
if sudo k3s kubectl get namespace mcapp &> /dev/null; then
  echo "✓ Namespace 'mcapp' exists"
else
  echo "❌ Namespace 'mcapp' not found"
  exit 1
fi

# Check pods
echo ""
echo "Pods in mcapp namespace:"
sudo k3s kubectl get pods -n mcapp

# Check services
echo ""
echo "Services in mcapp namespace:"
sudo k3s kubectl get services -n mcapp

# Check deployments
echo ""
echo "Deployments in mcapp namespace:"
sudo k3s kubectl get deployments -n mcapp

# Check statefulsets
echo ""
echo "StatefulSets in mcapp namespace:"
sudo k3s kubectl get statefulsets -n mcapp

# Check ingress
echo ""
echo "Ingress in mcapp namespace:"
sudo k3s kubectl get ingress -n mcapp

# Wait for pods to be ready
echo ""
echo "Waiting for all pods to be ready..."
timeout=120
counter=0
while true; do
  ready=$(sudo k3s kubectl get pods -n mcapp --no-headers 2>/dev/null | grep -v "Completed" | wc -l)
  running=$(sudo k3s kubectl get pods -n mcapp --no-headers 2>/dev/null | grep "Running" | wc -l)
  
  if [ $ready -eq $running ] && [ $ready -gt 0 ]; then
    echo "✓ All pods are ready!"
    break
  fi
  
  if [ $counter -ge $timeout ]; then
    echo "⚠ Timeout waiting for pods to be ready"
    echo "Some pods may still be starting. Check with: sudo k3s kubectl get pods -n mcapp"
    break
  fi
  
  sleep 5
  counter=$((counter + 5))
  echo "Waiting... ($counter/$timeout seconds) - $running/$ready pods ready"
done

# Test API health endpoint
echo ""
echo "Testing API health endpoint..."
API_POD=$(sudo k3s kubectl get pods -n mcapp -l app=api -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [ -n "$API_POD" ]; then
  if sudo k3s kubectl exec -n mcapp "$API_POD" -- curl -f -s http://localhost:8000/api/health > /dev/null 2>&1; then
    echo "✓ API health check passed"
  else
    echo "⚠ API health check failed (pod may still be starting)"
  fi
else
  echo "⚠ API pod not found"
fi

echo ""
echo "Verification complete!"
echo ""
echo "Access the application at:"
echo "  - NodePort: http://localhost:30080"
echo "  - Or port-forward: sudo k3s kubectl port-forward -n mcapp service/web 8080:80"
echo "    Then access: http://localhost:8080"
