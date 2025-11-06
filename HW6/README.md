# HW6 - Kubernetes Deployment with k3s

本作業將 HW5 的 Docker Swarm 部署轉換為 Kubernetes (k3s) 部署。

## 目錄結構

```
HW6/
├── content/
│   ├── k3s/              # Kubernetes manifests
│   │   ├── namespace.yaml
│   │   ├── database.yaml
│   │   ├── backend.yaml
│   │   ├── frontend.yaml
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   └── README.md
│   ├── swarm/            # 原 Docker Swarm 配置（保留參考）
│   ├── backend/          # 後端 API 源碼
│   ├── frontend/         # 前端源碼
│   └── db/               # 資料庫初始化腳本
├── ops/
│   ├── init-k3s.sh       # 安裝並初始化 k3s
│   ├── deploy-k3s.sh     # 部署應用到 k3s
│   ├── verify-k3s.sh     # 驗證部署狀態
│   ├── cleanup-k3s.sh    # 清理應用/卸載 k3s
│   ├── init-swarm.sh     # 原 Swarm 初始化（保留參考）
│   ├── deploy.sh         # 原 Swarm 部署（保留參考）
│   ├── verify.sh         # 原 Swarm 驗證（保留參考）
│   └── cleanup.sh        # 原 Swarm 清理（保留參考）
├── docs/
│   └── EVIDENCE.md       # 部署證明文件
└── spec/
    ├── speckit.constitution.md
    └── speckit.specify.md
```

## 部署方式對比

| 特性 | Docker Swarm (HW5) | k3s/Kubernetes (HW6) |
|------|-------------------|---------------------|
| 編排器 | Docker Swarm | Kubernetes (k3s) |
| 部署單位 | Stack | Deployment/StatefulSet |
| 網路 | Overlay network | CNI (Flannel) |
| 儲存 | Named volumes | PersistentVolumeClaim |
| 負載平衡 | 內建 LB | Service (ClusterIP/NodePort) |
| 擴展 | Stack 中的 replicas | `kubectl scale` |
| 配置 | Stack YAML | 多個 manifest 檔案 |
| Ingress | Routing mesh | Traefik (k3s 內建) |

## 快速開始 (k3s)

### 單節點部署（所有服務在同一台機器）

### 1. 安裝並初始化 k3s

```bash
cd ops
sudo bash init-k3s.sh
```

這會：
- 安裝 k3s（如果尚未安裝）
- 等待 k3s 就緒
- 配置 kubectl 存取

### 2. 部署應用

```bash
sudo bash deploy-k3s.sh
```

或先建置並推送映像檔：

```bash
sudo bash deploy-k3s.sh --build
```

### 3. 驗證部署

```bash
sudo bash verify-k3s.sh
```

### 4. 存取應用

應用可透過以下方式存取：

- **NodePort**: `http://localhost:30080` 或 `http://<node-ip>:30080`
- **Port-forward**:
  ```bash
  sudo k3s kubectl port-forward -n mcapp service/web 8080:80
  ```
  然後存取：`http://localhost:8080`

### 多節點部署（資料庫在實驗室機器）

**推薦用於本作業**，更接近生產環境！

詳細步驟請參考：[content/k3s/MULTI-NODE-SETUP.md](content/k3s/MULTI-NODE-SETUP.md)

#### 快速步驟：

**在筆電（Master）上：**
```bash
cd ops
sudo bash setup-multi-node.sh master
# 記下顯示的 TOKEN 和 IP
```

**在實驗室機器（Worker）上：**
```bash
sudo bash setup-multi-node.sh worker <LAPTOP_IP> <TOKEN>
```

**回到筆電，標記實驗室機器：**
```bash
sudo k3s kubectl label node <LAB_NODE_NAME> role=database
```

**部署應用：**
```bash
cd ops
sudo bash deploy-k3s.sh
```

**驗證資料庫在實驗室機器上：**
```bash
sudo k3s kubectl get pods -n mcapp -o wide
```

## 常用指令

### 查看 Pod 狀態
```bash
sudo k3s kubectl get pods -n mcapp
```

### 查看 Pod 日誌
```bash
# 後端日誌
sudo k3s kubectl logs -n mcapp -l app=api -f

# 前端日誌
sudo k3s kubectl logs -n mcapp -l app=web -f

# 資料庫日誌
sudo k3s kubectl logs -n mcapp -l app=db -f
```

### 擴展部署
```bash
# 擴展後端 API 到 3 個副本
sudo k3s kubectl scale deployment api -n mcapp --replicas=3

# 擴展前端到 2 個副本
sudo k3s kubectl scale deployment web -n mcapp --replicas=2
```

### 查看服務
```bash
sudo k3s kubectl get services -n mcapp
```

### 進入 Pod 執行指令
```bash
# 連接到資料庫
sudo k3s kubectl exec -it -n mcapp db-0 -- psql -U postgres -d appdb

# 進入 Pod shell
sudo k3s kubectl exec -it -n mcapp <pod-name> -- /bin/bash
```

## 清理

### 僅移除應用
```bash
cd ops
sudo bash cleanup-k3s.sh
```

### 移除應用並卸載 k3s
```bash
sudo bash cleanup-k3s.sh --uninstall-k3s
```

## Kubernetes 資源說明

### Namespace
- `mcapp`: 應用的命名空間，隔離資源

### Database (PostgreSQL)
- **類型**: StatefulSet
- **副本數**: 1
- **儲存**: PersistentVolumeClaim (5Gi)
- **服務**: ClusterIP (僅內部存取)
- **Port**: 5432

### Backend API
- **類型**: Deployment
- **副本數**: 2
- **映像檔**: `chien314832001/hw5_api:latest`
- **服務**: ClusterIP (僅內部存取)
- **Port**: 8000
- **健康檢查**: HTTP GET `/api/health`

### Frontend Web
- **類型**: Deployment
- **副本數**: 1
- **映像檔**: `chien314832001/hw5_web:latest`
- **服務**: NodePort (對外暴露在 30080)
- **Port**: 80
- **健康檢查**: HTTP GET `/`

### Ingress
- **控制器**: Traefik (k3s 內建)
- **路徑**: `/` → web service

## 配置

### Secrets
資料庫憑證儲存在 Kubernetes Secret (`postgres-secret`):
- Username: `postgres`
- Password: `password`
- Database: `appdb`

若要更新，編輯 `content/k3s/database.yaml` 並重新部署。

### 持久化儲存
PostgreSQL 資料透過 PersistentVolumeClaim 持久化 (5Gi)。
k3s 預設使用 local-path provisioner。

### 網路
- Database: ClusterIP (僅內部)
- Backend API: ClusterIP (僅內部)
- Frontend: NodePort (對外暴露)

## 故障排除

### Pod 無法啟動

檢查 Pod 事件：
```bash
sudo k3s kubectl describe pod -n mcapp <pod-name>
```

檢查 Pod 日誌：
```bash
sudo k3s kubectl logs -n mcapp <pod-name>
```

### 服務無法連接

檢查服務端點：
```bash
sudo k3s kubectl get endpoints -n mcapp
```

檢查 Pod 是否正在執行：
```bash
sudo k3s kubectl get pods -n mcapp
```

### 資料庫連接問題

驗證資料庫 Pod 正在執行：
```bash
sudo k3s kubectl get pods -n mcapp -l app=db
```

從後端 Pod 測試資料庫連接：
```bash
POD=$(sudo k3s kubectl get pod -n mcapp -l app=api -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl exec -n mcapp $POD -- curl -f http://db:5432
```

## 參考文件

- [k3s 官方文件](https://docs.k3s.io/)
- [Kubernetes 文件](https://kubernetes.io/docs/)
- [Traefik Ingress Controller](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)

## 原 Docker Swarm 版本

原始的 Docker Swarm 配置保留在 `content/swarm/` 目錄中作為參考。
相關腳本：
- `ops/init-swarm.sh` - 初始化 Swarm
- `ops/deploy.sh` - 部署到 Swarm
- `ops/verify.sh` - 驗證 Swarm 部署
- `ops/cleanup.sh` - 清理 Swarm

## 授權

本專案為 CCSA 課程作業。
