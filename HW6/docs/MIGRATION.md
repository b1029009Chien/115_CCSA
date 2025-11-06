# Docker Swarm vs k3s Migration Guide

本文件說明從 Docker Swarm (HW5) 遷移到 k3s (HW6) 的主要差異和對應關係。

## 架構對比

### Docker Swarm (HW5)
```
Manager Node (Student Laptop)
  ├── mcapp_web (replicas: 1)
  ├── mcapp_api (replicas: 1)
  └── Overlay Network: appnet

Worker Node (Lab Machine)
  └── mcapp_db (replicas: 1)
      └── Volume: dbdata → /var/lib/postgres-data
```

### k3s (HW6)
```
k3s Node
  ├── Namespace: mcapp
  │   ├── Deployment: web (replicas: 1)
  │   ├── Deployment: api (replicas: 2)
  │   └── StatefulSet: db (replicas: 1)
  │       └── PVC: postgres-pvc (5Gi)
  └── Network: Flannel CNI
```

## 概念對應表

| Docker Swarm | k3s/Kubernetes | 說明 |
|--------------|----------------|------|
| `docker stack deploy` | `kubectl apply` | 部署應用 |
| Stack YAML | Multiple Manifests | 配置檔案 |
| Service | Service | 服務發現和負載平衡 |
| Service (replicated) | Deployment | 無狀態應用 |
| Service (global) | DaemonSet | 每個節點一個 Pod |
| Volume | PersistentVolumeClaim | 持久化儲存 |
| Overlay Network | CNI (Flannel) | 容器網路 |
| Secrets | Secrets | 敏感資訊儲存 |
| Configs | ConfigMap | 配置資料 |
| Constraints | NodeSelector/Affinity | 節點選擇 |
| Ingress Routing Mesh | Ingress Controller | 外部流量路由 |

## 命令對照表

### 部署

| 任務 | Docker Swarm | k3s |
|------|--------------|-----|
| 初始化集群 | `docker swarm init` | `curl -sfL https://get.k3s.io \| sh -` |
| 部署應用 | `docker stack deploy -c stack.yaml mcapp` | `kubectl apply -f k3s/` |
| 列出服務 | `docker service ls` | `kubectl get deployments -n mcapp` |
| 查看任務 | `docker service ps mcapp_api` | `kubectl get pods -n mcapp -l app=api` |
| 擴展服務 | `docker service scale mcapp_api=3` | `kubectl scale deployment api --replicas=3 -n mcapp` |
| 更新服務 | `docker service update --image ... mcapp_api` | `kubectl set image deployment/api api=... -n mcapp` |
| 查看日誌 | `docker service logs mcapp_api` | `kubectl logs -n mcapp -l app=api` |
| 移除應用 | `docker stack rm mcapp` | `kubectl delete namespace mcapp` |

### 監控

| 任務 | Docker Swarm | k3s |
|------|--------------|-----|
| 查看節點 | `docker node ls` | `kubectl get nodes` |
| 節點詳情 | `docker node inspect <node>` | `kubectl describe node <node>` |
| 服務詳情 | `docker service inspect mcapp_api` | `kubectl describe deployment api -n mcapp` |
| 任務/Pod 詳情 | `docker inspect <container>` | `kubectl describe pod <pod> -n mcapp` |
| 即時日誌 | `docker service logs -f mcapp_api` | `kubectl logs -f -n mcapp -l app=api` |
| 進入容器 | `docker exec -it <container> bash` | `kubectl exec -it <pod> -n mcapp -- bash` |

### 網路

| 任務 | Docker Swarm | k3s |
|------|--------------|-----|
| 建立網路 | `docker network create -d overlay appnet` | 自動 (由 CNI 管理) |
| 列出網路 | `docker network ls` | `kubectl get networkpolicies -n mcapp` |
| 服務發現 | DNS: `<service-name>` | DNS: `<service-name>.<namespace>.svc.cluster.local` |

### 儲存

| 任務 | Docker Swarm | k3s |
|------|--------------|-----|
| 建立 Volume | `docker volume create dbdata` | `kubectl apply -f pvc.yaml` |
| 列出 Volumes | `docker volume ls` | `kubectl get pvc -n mcapp` |
| 檢查 Volume | `docker volume inspect dbdata` | `kubectl describe pvc postgres-pvc -n mcapp` |

## 配置檔案對比

### Docker Swarm Stack YAML

```yaml
version: "3.8"
services:
  api:
    image: chien314832001/hw5_api:latest
    environment:
      - POSTGRES_HOST=db
    networks:
      - appnet
    
  db:
    image: postgres:16
    volumes:
      - dbdata:/var/lib/postgresql/data
    networks:
      - appnet
    deploy:
      placement:
        constraints:
          - node.labels.role == db

networks:
  appnet:
    driver: overlay

volumes:
  dbdata: {}
```

### k3s Kubernetes Manifests

**backend.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: mcapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: chien314832001/hw5_api:latest
        env:
        - name: POSTGRES_HOST
          value: "db"
---
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: mcapp
spec:
  selector:
    app: api
  ports:
  - port: 8000
```

**database.yaml**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
  namespace: mcapp
spec:
  serviceName: db
  replicas: 1
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: postgres
        image: postgres:16
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
  namespace: mcapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

## 部署流程對比

### Docker Swarm 部署流程

```bash
# 1. 初始化 Swarm (管理節點)
docker swarm init

# 2. 加入工作節點
docker swarm join --token <token> <manager-ip>:2377

# 3. 標記節點
docker node update --label-add role=db <worker-node>

# 4. 建立網路
docker network create -d overlay appnet

# 5. 部署應用
docker stack deploy -c swarm/stack.yaml mcapp

# 6. 驗證
docker service ls
docker service ps mcapp_db
```

### k3s 部署流程

```bash
# 1. 安裝 k3s
curl -sfL https://get.k3s.io | sh -

# 2. 等待就緒
sudo k3s kubectl get nodes

# 3. 部署應用
sudo k3s kubectl apply -f k3s/namespace.yaml
sudo k3s kubectl apply -f k3s/database.yaml
sudo k3s kubectl apply -f k3s/backend.yaml
sudo k3s kubectl apply -f k3s/frontend.yaml

# 4. 驗證
sudo k3s kubectl get all -n mcapp
sudo k3s kubectl get pods -n mcapp
```

## 功能差異

### Docker Swarm 特性

**優點:**
- 設定簡單，單一 YAML 檔案
- 與 Docker 緊密整合
- 較低的學習曲線
- 內建服務發現和負載平衡

**限制:**
- 功能較少
- 生態系統較小
- 擴展性有限
- 較少企業級功能

### k3s/Kubernetes 特性

**優點:**
- 功能豐富
- 強大的擴展性
- 大型生態系統
- 企業級功能 (RBAC, Network Policies, etc.)
- 更精細的資源控制
- 更好的監控和日誌整合

**複雜性:**
- 學習曲線較陡
- 需要多個 manifest 檔案
- 配置較複雜
- 需要更多資源

## 遷移考量

### 何時使用 Docker Swarm
- 簡單的應用部署
- 小型團隊或專案
- 快速原型開發
- 與 Docker Compose 工作流程一致

### 何時使用 k3s/Kubernetes
- 生產環境
- 需要高可用性
- 複雜的微服務架構
- 需要進階功能 (RBAC, Network Policies)
- 計劃擴展到多叢集

## 實際案例對比

### 擴展後端 API 到 3 個副本

**Docker Swarm:**
```bash
docker service scale mcapp_api=3
docker service ps mcapp_api
```

**k3s:**
```bash
sudo k3s kubectl scale deployment api -n mcapp --replicas=3
sudo k3s kubectl get pods -n mcapp -l app=api
```

### 查看應用程式日誌

**Docker Swarm:**
```bash
docker service logs mcapp_api -f
```

**k3s:**
```bash
sudo k3s kubectl logs -n mcapp -l app=api -f
```

### 更新應用程式映像檔

**Docker Swarm:**
```bash
docker service update --image chien314832001/hw5_api:v2 mcapp_api
```

**k3s:**
```bash
sudo k3s kubectl set image deployment/api -n mcapp api=chien314832001/hw5_api:v2
sudo k3s kubectl rollout status deployment/api -n mcapp
```

## 網路差異

### Docker Swarm
- Overlay 網路自動建立
- 服務發現透過 DNS: `<service-name>`
- 內建 Load Balancer (Routing Mesh)
- 簡單的 port 映射

### k3s/Kubernetes
- CNI (Flannel) 管理網路
- 服務發現: `<service-name>.<namespace>.svc.cluster.local`
- Service 提供 Load Balancing
- Ingress Controller (Traefik) 處理外部流量
- NetworkPolicy 提供網路隔離

## 儲存差異

### Docker Swarm
- Named volumes
- 可選 volume driver
- 簡單的 bind mounts
- 節點本地儲存

### k3s/Kubernetes
- PersistentVolume (PV) 和 PersistentVolumeClaim (PVC)
- StorageClass 支援
- local-path-provisioner (k3s 預設)
- 支援各種儲存後端 (NFS, Ceph, etc.)
- 更精細的儲存管理

## 總結

| 特性 | Docker Swarm | k3s/Kubernetes |
|------|--------------|----------------|
| 複雜度 | ⭐⭐ | ⭐⭐⭐⭐ |
| 功能 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 擴展性 | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| 生態系統 | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| 學習曲線 | 平緩 | 陡峭 |
| 適用場景 | 小型應用 | 企業級應用 |
| 社群支援 | 中等 | 非常活躍 |

k3s 是 Kubernetes 的輕量級版本，在保持 Kubernetes 強大功能的同時，降低了資源需求，非常適合邊緣計算、IoT 和開發環境使用。
