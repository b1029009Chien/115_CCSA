#!/usr/bin/env bash
set -euo pipefail

# setup-multi-node.sh
# Setup k3s multi-node cluster with database on lab machine

usage() {
  cat <<EOF
Usage: 
  On LAPTOP (master):  $0 master
  On LAB MACHINE (worker): $0 worker <LAPTOP_IP> <TOKEN>

Examples:
  # Step 1: Run on laptop
  sudo bash setup-multi-node.sh master

  # Step 2: Run on lab machine (use token and IP from step 1)
  sudo bash setup-multi-node.sh worker 192.168.1.100 K10abc...xyz::server:abc123

This script helps setup a multi-node k3s cluster.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

MODE=$1

case $MODE in
  master)
    echo "=== Setting up k3s Master (Server) ==="
    echo ""
    
    # Install k3s server
    echo "Installing k3s server..."
    curl -sfL https://get.k3s.io | sh -s - server --write-kubeconfig-mode 644
    
    echo ""
    echo "Waiting for k3s to be ready..."
    sleep 10
    
    # Wait for k3s to be ready
    timeout=60
    counter=0
    while ! k3s kubectl get nodes &> /dev/null; do
      if [ $counter -ge $timeout ]; then
        echo "Timeout waiting for k3s" >&2
        exit 1
      fi
      sleep 2
      counter=$((counter + 2))
    done
    
    echo ""
    echo "✓ k3s server installed successfully!"
    echo ""
    echo "=== IMPORTANT INFORMATION ==="
    echo ""
    echo "1. Master Node Token (needed for worker):"
    echo "---"
    cat /var/lib/rancher/k3s/server/node-token
    echo "---"
    echo ""
    
    echo "2. Master Node IP addresses:"
    echo "---"
    hostname -I
    echo "---"
    echo ""
    
    echo "3. Next steps:"
    echo "   a) Note the TOKEN above"
    echo "   b) Choose the appropriate IP address (usually the first one)"
    echo "   c) On your LAB MACHINE, run:"
    echo "      sudo bash setup-multi-node.sh worker <LAPTOP_IP> <TOKEN>"
    echo ""
    echo "   Example:"
    FIRST_IP=$(hostname -I | awk '{print $1}')
    TOKEN_PREVIEW=$(cat /var/lib/rancher/k3s/server/node-token | head -c 20)
    echo "      sudo bash setup-multi-node.sh worker $FIRST_IP ${TOKEN_PREVIEW}..."
    echo ""
    
    echo "4. Verify nodes (after worker joins):"
    echo "      sudo k3s kubectl get nodes"
    echo ""
    ;;
    
  worker)
    if [[ $# -lt 3 ]]; then
      echo "Error: worker mode requires LAPTOP_IP and TOKEN" >&2
      echo ""
      usage
      exit 1
    fi
    
    MASTER_IP=$2
    TOKEN=$3
    
    echo "=== Setting up k3s Worker (Agent) ==="
    echo ""
    echo "Master IP: $MASTER_IP"
    echo "Token: ${TOKEN:0:20}..." # Show only first 20 chars
    echo ""
    
    # Test connection to master
    echo "Testing connection to master..."
    if curl -k --connect-timeout 5 https://$MASTER_IP:6443 &> /dev/null; then
      echo "✓ Can connect to master"
    else
      echo "✗ Cannot connect to master at https://$MASTER_IP:6443" >&2
      echo "  Please check:"
      echo "  - Master IP is correct"
      echo "  - Master is running"
      echo "  - Firewall allows port 6443"
      exit 1
    fi
    
    echo ""
    echo "Installing k3s agent..."
    curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN sh -
    
    echo ""
    echo "Waiting for k3s agent to start..."
    sleep 10
    
    echo ""
    echo "✓ k3s agent installed successfully!"
    echo ""
    echo "=== Next steps ==="
    echo ""
    echo "1. On LAPTOP (master), verify the node joined:"
    echo "      sudo k3s kubectl get nodes"
    echo ""
    echo "2. On LAPTOP, label this node for database:"
    echo "      sudo k3s kubectl label node $(hostname) role=database"
    echo ""
    echo "3. On LAB MACHINE (this machine), prepare storage directory:"
    echo "      sudo mkdir -p /var/lib/postgres-data"
    echo "      sudo chmod 777 /var/lib/postgres-data"
    echo ""
    echo "4. On LAPTOP, deploy the application:"
    echo "      cd HW6/ops"
    echo "      sudo bash deploy-k3s.sh"
    echo ""
    ;;
    
  *)
    echo "Error: Invalid mode '$MODE'. Must be 'master' or 'worker'" >&2
    usage
    exit 1
    ;;
esac

echo "Setup complete!"
