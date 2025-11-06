# HW6 架構說明

## 部署架構選項

### 選項 1: 單節點部署（簡單）

所有服務運行在同一台機器上。

```
┌────────────────────────────────────────────┐
│  單台機器 (筆電或實驗室機器)               │
│  ┌──────────────────────────────────────┐  │
│  │  k3s Cluster                         │  │
│  │  ┌────────────────────────────────┐  │  │
│  │  │  Namespace: mcapp              │  │  │
│  │  │  ┌──────────┐  ┌──────────┐   │  │  │
│  │  │  │   web    │  │   api    │   │  │  │
│  │  │  │ (1 rep)  │  │ (2 reps) │   │  │  │
│  │  │  └──────────┘  └──────────┘   │  │  │
│  │  │  ┌──────────────────────┐     │  │  │
│  │  │  │   db (PostgreSQL)    │     │  │  │
│  │  │  │   + PVC (5Gi)        │     │  │  │
│  │  │  └──────────────────────┘     │  │  │
│  │  └────────────────────────────────┘  │  │
│  └──────────────────────────────────────┘  │
└────────────────────────────────────────────┘
```

**優點：**
- ✅ 設定簡單
- ✅ 適合測試和開發

**缺點：**
- ❌ 所有資源在同一台機器
- ❌ 無法展示分散式架構

**適用場景：**
- 快速測試
- 只有一台機器可用

---

### 選項 2: 多節點部署（推薦）

資料庫在實驗室機器，其他服務在筆電。

```
┌─────────────────────────────────────────────┐
│  筆電 (k3s Master/Server)                   │
│  IP: 例如 192.168.1.100                     │
│  ┌───────────────────────────────────────┐  │
│  │  k3s Control Plane                    │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │  Namespace: mcapp               │  │  │
│  │  │  ┌──────────┐  ┌──────────┐    │  │  │
│  │  │  │   web    │  │   api    │    │  │  │
│  │  │  │ NodePort │  │ (2 reps) │    │  │  │
│  │  │  │  :30080  │  │          │    │  │  │
│  │  │  └──────────┘  └──────────┘    │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
└──────────────────┬──────────────────────────┘
                   │
                   │ k3s Network (Port 6443, 10250, 8472)
                   │
┌──────────────────┴──────────────────────────┐
│  實驗室機器 (k3s Worker/Agent)              │
│  IP: 例如 192.168.1.200                     │
│  Label: role=database                       │
│  ┌───────────────────────────────────────┐  │
│  │  k3s Agent                            │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │  Namespace: mcapp               │  │  │
│  │  │  ┌───────────────────────────┐  │  │  │
│  │  │  │   db (PostgreSQL)         │  │  │  │
│  │  │  │   StatefulSet (1 rep)     │  │  │  │
│  │  │  │   ┌─────────────────────┐ │  │  │  │
│  │  │  │   │  PVC (5Gi)          │ │  │  │  │
│  │  │  │   │  Local Storage      │ │  │  │  │
│  │  │  │   └─────────────────────┘ │  │  │  │
│  │  │  └───────────────────────────┘  │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

**優點：**
- ✅ 資源分散，更高效
- ✅ 展示真實的分散式架構
- ✅ 資料庫 I/O 獨立
- ✅ 更接近生產環境

**缺點：**
- ⚠️ 需要兩台機器
- ⚠️ 網路配置較複雜

**適用場景：**
- 本次作業（有實驗室機器）
- 生產環境模擬

---

## 網路通訊詳解

### k3s 需要的端口

| 端口 | 協議 | 用途 | 方向 |
|------|------|------|------|
| 6443 | TCP | Kubernetes API Server | Worker → Master |
| 10250 | TCP | Kubelet API | Master ↔ Worker |
| 8472 | UDP | Flannel VXLAN | Master ↔ Worker |
| 2379-2380 | TCP | etcd (僅 Master) | Master 內部 |

### 應用層通訊

```
用戶瀏覽器
    ↓ HTTP :30080 (NodePort)
┌───┴────────────────────────┐
│  Frontend (web)            │
│  - 提供 HTML/CSS/JS        │
│  - Nginx                   │
└────────┬───────────────────┘
         │ HTTP :8000
         ↓
┌────────┴───────────────────┐
│  Backend (api)             │
│  - Python FastAPI          │
│  - 業務邏輯                │
└────────┬───────────────────┘
         │ PostgreSQL :5432
         ↓
┌────────┴───────────────────┐
│  Database (db)             │
│  - PostgreSQL 16           │
│  - 資料持久化              │
└────────────────────────────┘
```

**服務發現（DNS）：**
- Frontend → Backend: `http://api:8000`
- Backend → Database: `postgresql://db:5432/appdb`

Kubernetes 內建 DNS 自動解析服務名稱。

---

## 資料持久化

### StatefulSet vs Deployment

| 特性 | Deployment | StatefulSet |
|------|-----------|-------------|
| 用途 | 無狀態應用 | 有狀態應用 |
| Pod 名稱 | 隨機後綴 | 固定編號 (db-0, db-1) |
| 網路識別 | 不穩定 | 穩定 (db-0.db) |
| 儲存 | 可選 | 與 Pod 綁定 |
| 擴展順序 | 並行 | 順序 (0→1→2) |

**為什麼資料庫用 StatefulSet？**
- ✅ 穩定的網路識別
- ✅ 有序的部署和擴展
- ✅ 持久化儲存與 Pod 生命週期綁定

### 儲存架構

```
┌─────────────────────────────────────┐
│  Database Pod (db-0)                │
│  ┌───────────────────────────────┐  │
│  │  PostgreSQL Container         │  │
│  │  Mount: /var/lib/postgresql/  │  │
│  └───────────┬───────────────────┘  │
└──────────────┼──────────────────────┘
               │
               ↓ volumeMount
┌──────────────┴──────────────────────┐
│  PersistentVolumeClaim (PVC)        │
│  - Name: postgres-pvc               │
│  - Size: 5Gi                        │
│  - AccessMode: ReadWriteOnce        │
└──────────────┬──────────────────────┘
               │
               ↓ 綁定
┌──────────────┴──────────────────────┐
│  PersistentVolume (PV)              │
│  - 自動創建 (by local-path)         │
│  - HostPath: /var/lib/rancher/...   │
└──────────────┬──────────────────────┘
               │
               ↓ 實際儲存
┌──────────────┴──────────────────────┐
│  實驗室機器本地磁碟                 │
│  /var/lib/rancher/k3s/storage/...   │
└─────────────────────────────────────┘
```

**重要特性：**
- PVC 請求儲存空間
- PV 提供實際儲存
- local-path-provisioner 自動創建 PV
- 資料保留在運行 Pod 的節點上

---

## 負載平衡與服務發現

### Service 類型

#### ClusterIP (Backend & Database)
```
┌─────────────────────────────┐
│  Service: api (ClusterIP)   │
│  IP: 10.43.xxx.xxx          │
│  Port: 8000                 │
└────────┬────────────────────┘
         │ 負載平衡
    ┌────┼────┐
    ↓    ↓    ↓
┌────┐ ┌────┐ ┌────┐
│api │ │api │ │... │
│ -0 │ │ -1 │ │    │
└────┘ └────┘ └────┘
```

- 只能在叢集內部存取
- 自動負載平衡到所有 Pods
- 穩定的虛擬 IP

#### NodePort (Frontend)
```
外部流量
    ↓ :30080
┌────┴──────────────────────┐
│  任何節點的 IP:30080       │
│  (筆電或實驗室機器)        │
└────┬──────────────────────┘
     │
     ↓ 轉發到
┌────┴──────────────────────┐
│  Service: web (NodePort)  │
│  ClusterIP: 10.43.xxx.xxx │
│  NodePort: 30080          │
└────┬──────────────────────┘
     │
     ↓
┌────┴────┐
│  web-0  │
└─────────┘
```

- 在所有節點上開放端口
- 可從外部存取
- 適合開發和測試

---

## 部署流程詳解

### 單節點部署流程

```
1. 安裝 k3s
   └─→ curl -sfL https://get.k3s.io | sh -
       └─→ k3s server 啟動
           └─→ API Server (:6443)
           └─→ Scheduler
           └─→ Controller Manager
           └─→ local-path-provisioner
           └─→ Traefik Ingress

2. 部署 Namespace
   └─→ kubectl apply -f namespace.yaml
       └─→ 創建 'mcapp' namespace

3. 部署 Database
   └─→ kubectl apply -f database.yaml
       └─→ 創建 Secret (postgres-secret)
       └─→ 創建 ConfigMap (postgres-init)
       └─→ 創建 PVC (postgres-pvc)
       │   └─→ local-path-provisioner 創建 PV
       └─→ 創建 Service (db)
       └─→ 創建 StatefulSet (db)
           └─→ 調度 Pod: db-0
               └─→ 掛載 PVC
               └─→ 運行 PostgreSQL

4. 部署 Backend
   └─→ kubectl apply -f backend.yaml
       └─→ 創建 Service (api)
       └─→ 創建 Deployment (api)
           └─→ 調度 Pods: api-xxx (2個)
               └─→ 連接到 db:5432

5. 部署 Frontend
   └─→ kubectl apply -f frontend.yaml
       └─→ 創建 Service (web, NodePort)
       └─→ 創建 Deployment (web)
           └─→ 調度 Pod: web-xxx
               └─→ 代理請求到 api:8000

6. 驗證
   └─→ 所有 Pods Running
   └─→ Services 有 Endpoints
   └─→ 存取 http://localhost:30080
```

### 多節點部署流程

```
筆電 (Master)                    實驗室機器 (Worker)
     │                                │
1. 安裝 k3s server                   │
   └─→ curl ... | sh -s - server     │
       └─→ 生成 Token                │
       └─→ 監聽 :6443                │
     │                                │
2. ─────── 提供 Token 和 IP ────────→ 3. 安裝 k3s agent
     │                                    └─→ K3S_URL=https://...:6443
     │                                    └─→ K3S_TOKEN=...
     │                                    └─→ 連接到 Master
     │                                    └─→ 註冊為 Worker
     │                                │
4. 驗證節點                          │
   └─→ kubectl get nodes             │
       ├─→ laptop (Master)           │
       └─→ lab-machine (Worker) ←────┘
     │                                │
5. 標記 Worker                       │
   └─→ kubectl label node            │
       lab-machine role=database     │
     │                                │
6. 部署應用                          │
   └─→ kubectl apply -f ...          │
       ├─→ web, api → 筆電           │
       └─→ db → 實驗室機器 ──────────→ 7. 運行 Database Pod
     │                                    └─→ 使用本地儲存
     │                                    └─→ 監聽 :5432
     │                                │
8. 服務通訊                          │
   ├─→ web → api (叢集內)           │
   └─→ api → db (跨節點) ←──────────┘
     │                                │
9. 外部存取                          │
   └─→ :30080 → web                 │
       (任一節點 IP)                  │
```

---

## 故障處理與除錯

### 常見問題診斷流程

```
問題：應用無法存取
    ↓
檢查 Pods 狀態
    ├─→ kubectl get pods -n mcapp
    │   ├─→ Pending → 檢查資源/調度
    │   ├─→ CrashLoopBackOff → 檢查日誌
    │   └─→ Running → 繼續
    ↓
檢查 Services
    ├─→ kubectl get svc -n mcapp
    │   └─→ kubectl get endpoints -n mcapp
    │       └─→ 無 Endpoints → Pod 選擇器錯誤
    ↓
檢查網路連接
    ├─→ kubectl exec -it <pod> -- curl api:8000
    │   └─→ 失敗 → DNS 或網路問題
    ↓
檢查應用日誌
    └─→ kubectl logs -n mcapp <pod>
        └─→ 查看錯誤訊息
```

---

這個架構說明應該能幫助您理解整個系統的運作方式！
