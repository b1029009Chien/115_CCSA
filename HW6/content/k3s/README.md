# k3s Deployment Guide

This directory contains Kubernetes manifests for deploying the application on k3s.

## Architecture

The application consists of three main components:

- **Database (PostgreSQL)**: Deployed as a StatefulSet with persistent storage
- **Backend API**: Deployed as a Deployment with 2 replicas
- **Frontend Web**: Deployed as a Deployment with 1 replica

## Prerequisites

- Linux system (Ubuntu, Debian, CentOS, etc.)
- Docker installed (for building images)
- sudo access

## Quick Start

### 1. Install and Initialize k3s

```bash
cd ops
sudo bash init-k3s.sh
```

This will:
- Install k3s if not already installed
- Wait for k3s to be ready
- Configure kubectl access

### 2. Deploy the Application

```bash
sudo bash deploy-k3s.sh
```

Or build and push images before deploying:

```bash
sudo bash deploy-k3s.sh --build
```

### 3. Verify the Deployment

```bash
sudo bash verify-k3s.sh
```

This will check:
- Cluster status
- Pod status
- Service status
- API health endpoint

### 4. Access the Application

The application is accessible via:

- **NodePort**: `http://localhost:30080` or `http://<node-ip>:30080`
- **Port-forward**: 
  ```bash
  sudo k3s kubectl port-forward -n mcapp service/web 8080:80
  ```
  Then access: `http://localhost:8080`

## Useful Commands

### Check Pod Status
```bash
sudo k3s kubectl get pods -n mcapp
```

### View Pod Logs
```bash
# Backend logs
sudo k3s kubectl logs -n mcapp -l app=api -f

# Frontend logs
sudo k3s kubectl logs -n mcapp -l app=web -f

# Database logs
sudo k3s kubectl logs -n mcapp -l app=db -f
```

### Scale Deployments
```bash
# Scale backend API
sudo k3s kubectl scale deployment api -n mcapp --replicas=3

# Scale frontend
sudo k3s kubectl scale deployment web -n mcapp --replicas=2
```

### Describe Resources
```bash
sudo k3s kubectl describe deployment api -n mcapp
sudo k3s kubectl describe service web -n mcapp
sudo k3s kubectl describe statefulset db -n mcapp
```

### Execute Commands in Pods
```bash
# Connect to database
sudo k3s kubectl exec -it -n mcapp db-0 -- psql -U postgres -d appdb

# Shell into a pod
sudo k3s kubectl exec -it -n mcapp <pod-name> -- /bin/bash
```

## Cleanup

### Remove Application Only
```bash
cd ops
sudo bash cleanup-k3s.sh
```

### Remove Application and Uninstall k3s
```bash
sudo bash cleanup-k3s.sh --uninstall-k3s
```

## Manifest Files

- `namespace.yaml`: Creates the `mcapp` namespace
- `database.yaml`: PostgreSQL StatefulSet, Service, PVC, ConfigMap, and Secret
- `backend.yaml`: Backend API Deployment and Service
- `frontend.yaml`: Frontend Web Deployment and Service (NodePort)
- `ingress.yaml`: Ingress configuration for Traefik
- `kustomization.yaml`: Kustomize configuration (optional)

## Configuration

### Secrets

Database credentials are stored in Kubernetes Secrets (`postgres-secret`):
- Username: `postgres`
- Password: `password`
- Database: `appdb`

To update secrets, edit `database.yaml` and redeploy.

### Storage

PostgreSQL data is persisted using a PersistentVolumeClaim (5Gi).
k3s uses local-path provisioner by default.

### Networking

- Database: ClusterIP (internal only)
- Backend API: ClusterIP (internal only)
- Frontend: NodePort (exposed on port 30080)

## Troubleshooting

### Pods Not Starting

Check pod events:
```bash
sudo k3s kubectl describe pod -n mcapp <pod-name>
```

Check pod logs:
```bash
sudo k3s kubectl logs -n mcapp <pod-name>
```

### Service Not Accessible

Check service endpoints:
```bash
sudo k3s kubectl get endpoints -n mcapp
```

Check if pods are running:
```bash
sudo k3s kubectl get pods -n mcapp
```

### Database Connection Issues

Verify database pod is running:
```bash
sudo k3s kubectl get pods -n mcapp -l app=db
```

Test database connection from backend pod:
```bash
POD=$(sudo k3s kubectl get pod -n mcapp -l app=api -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl exec -n mcapp $POD -- curl -f http://db:5432
```

## Differences from Docker Swarm

| Feature | Docker Swarm | k3s/Kubernetes |
|---------|--------------|----------------|
| Orchestrator | Docker Swarm | Kubernetes (k3s) |
| Deployment Unit | Stack | Deployment/StatefulSet |
| Networking | Overlay network | CNI (Flannel in k3s) |
| Storage | Named volumes | PersistentVolumeClaim |
| Load Balancing | Internal LB | Service (ClusterIP/NodePort) |
| Scaling | Replicas in stack | `kubectl scale` |
| Configuration | Stack YAML | Multiple manifest files |

## Notes

- k3s includes Traefik as the default ingress controller
- k3s uses local-path-provisioner for persistent storage
- All resources are deployed in the `mcapp` namespace
- The frontend is exposed via NodePort for easy access
