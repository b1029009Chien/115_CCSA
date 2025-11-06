# k3s Multi-Node Deployment Guide

本指南說明如何設定多節點 k3s 叢集，將資料庫部署到實驗室機器（worker node）。

## ⚠️ 重要前提

**k3s 需要 Linux 系統！**

- ✅ 可用：Ubuntu, Debian, CentOS, RHEL, Fedora 等 Linux 發行版
- ❌ 不可用：Windows (需要透過 WSL2)
- ❌ 不可用：macOS (需要透過虛擬機)

### 如果您使用 Windows

您有以下選擇：

1. **使用 WSL2**（推薦用於本地測試）
   ```powershell
   # 在 PowerShell (管理員) 中執行
   wsl --install -d Ubuntu
   # 重啟後進入 WSL2：wsl
   ```

2. **直接在實驗室 Linux 機器上部署**（最推薦）
   - SSH 連接到實驗室機器
   - 在實驗室機器上安裝和運行 k3s
   - 從 Windows 透過瀏覽器存取應用

3. **使用虛擬機**（VirtualBox, VMware）
   - 安裝 Ubuntu VM
   - 在 VM 中運行 k3s

**本指南的其餘部分假設您在 Linux 環境中執行。**

---

## 架構概覽

```
┌─────────────────────────────────────┐
│  Student Laptop (k3s Server/Master)│
│  ┌──────────┐  ┌──────────┐        │
│  │   web    │  │   api    │        │
│  │ (nginx)  │  │ (python) │        │
│  └──────────┘  └──────────┘        │
└─────────────────┬───────────────────┘
                  │ k3s network
┌─────────────────┴───────────────────┐
│  Lab Machine (k3s Agent/Worker)    │
│  ┌──────────────────────┐          │
│  │   db (PostgreSQL)    │          │
│  │  + Persistent Volume │          │
│  └──────────────────────┘          │
└─────────────────────────────────────┘
```

## 部署步驟

### 步驟 1: 在筆電上安裝 k3s Server (Master)

```bash
# 在筆電上執行
curl -sfL https://get.k3s.io | sh -s - server \
  --write-kubeconfig-mode 644 \
  --node-taint node-role.kubernetes.io/master=true:NoSchedule

# 這會：
# - 安裝 k3s server (master node)
# - 添加 taint，防止在 master 上調度 pods（可選）
# - 設定適當的 kubeconfig 權限
```

**取得 Token（重要）：**
```bash
# 在筆電上執行，記下這個 token
sudo cat /var/lib/rancher/k3s/server/node-token

# 輸出類似：
# K10abc123def456ghi789jkl012mno345pqr678stu901vwx234yz::server:abc123def456
```

**取得 Master IP（重要）：**
```bash
# 在筆電上執行
ip addr show | grep "inet "
# 或
hostname -I | awk '{print $1}'

# 記下您的筆電 IP，例如：192.168.1.100
```

### 步驟 2: 在實驗室機器上安裝 k3s Agent (Worker)

```bash
# 在實驗室機器上執行
# 替換 <LAPTOP_IP> 和 <TOKEN>
curl -sfL https://get.k3s.io | K3S_URL=https://<LAPTOP_IP>:6443 \
  K3S_TOKEN=<TOKEN> sh -

# 範例：
# curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.100:6443 \
#   K3S_TOKEN=K10abc123...xyz::server:abc123 sh -
```

### 步驟 3: 驗證叢集

```bash
# 在筆電上執行
sudo k3s kubectl get nodes

# 應該看到兩個節點：
# NAME          STATUS   ROLES                  AGE   VERSION
# laptop        Ready    control-plane,master   5m    v1.28.x
# lab-machine   Ready    <none>                 2m    v1.28.x
```

### 步驟 4: 標記實驗室機器為資料庫節點

```bash
# 在筆電上執行
# 取得實驗室機器的節點名稱
LAB_NODE=$(sudo k3s kubectl get nodes -o jsonpath='{.items[?(@.metadata.name!="'$(hostname)'")].metadata.name}')

# 或手動指定
LAB_NODE="lab-machine"  # 替換為實際名稱

# 添加標籤
sudo k3s kubectl label node $LAB_NODE role=database

# 驗證標籤
sudo k3s kubectl get nodes --show-labels
```

### 步驟 5: 在實驗室機器上準備儲存目錄

```bash
# 在實驗室機器上執行
sudo mkdir -p /var/lib/postgres-data
sudo chmod 777 /var/lib/postgres-data  # 或更安全的權限設定
```

### 步驟 6: 部署應用

```bash
# 在筆電上執行
cd HW6/ops
sudo bash deploy-k3s.sh
```

## 設定說明

### database.yaml 的節點選擇器

確保 database.yaml 包含 nodeSelector：

```yaml
spec:
  template:
    spec:
      nodeSelector:
        role: database  # 確保資料庫只部署在標記的節點上
```

### 網路需求

兩台機器需要能夠相互通信：
- **Port 6443**: k3s API server (TCP)
- **Port 10250**: kubelet (TCP)
- **Port 8472**: Flannel VXLAN (UDP) - 如果使用 Flannel
- **Port 51820**: Flannel WireGuard (UDP) - 如果使用 WireGuard

檢查防火牆：
```bash
# Ubuntu/Debian
sudo ufw allow 6443/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 8472/udp

# 或暫時關閉防火牆進行測試
sudo ufw disable
```

## 常用管理指令

### 查看節點狀態
```bash
sudo k3s kubectl get nodes -o wide
```

### 查看哪個節點運行哪些 Pods
```bash
sudo k3s kubectl get pods -n mcapp -o wide
```

### 強制將 Pod 調度到特定節點
```bash
# 使用 nodeSelector (已在 database.yaml 中配置)
```

### 從實驗室機器移除 k3s
```bash
# 在實驗室機器上執行
sudo /usr/local/bin/k3s-agent-uninstall.sh
```

### 從筆電移除 k3s
```bash
# 在筆電上執行
sudo /usr/local/bin/k3s-uninstall.sh
```

## 故障排除

### Worker 無法加入叢集

**檢查網路連接：**
```bash
# 在實驗室機器上測試
curl -k https://<LAPTOP_IP>:6443

# 應該返回未授權錯誤（這是正常的，表示可以連接）
```

**檢查 Token：**
```bash
# 在筆電上重新取得 token
sudo cat /var/lib/rancher/k3s/server/node-token
```

**檢查日誌：**
```bash
# 在實驗室機器上
sudo journalctl -u k3s-agent -f
```

### Pod 沒有調度到正確的節點

**檢查節點標籤：**
```bash
sudo k3s kubectl get nodes --show-labels
```

**檢查 Pod 事件：**
```bash
sudo k3s kubectl describe pod -n mcapp db-0
```

**檢查節點是否有 taints：**
```bash
sudo k3s kubectl describe node <node-name> | grep Taints
```

### 資料庫無法持久化

**檢查 PVC 狀態：**
```bash
sudo k3s kubectl get pvc -n mcapp
sudo k3s kubectl describe pvc postgres-pvc -n mcapp
```

**在實驗室機器上檢查目錄：**
```bash
# 在實驗室機器上
ls -la /var/lib/rancher/k3s/storage/
```

## 進階配置

### 使用 Local Path Provisioner (推薦)

k3s 預設使用 local-path-provisioner，會自動在運行 Pod 的節點上創建目錄。

**優點：**
- 自動管理
- 無需手動創建目錄
- 簡單易用

**缺點：**
- 資料綁定到特定節點
- Pod 無法遷移到其他節點

### 使用 NFS (進階)

如果需要在多個節點間共享資料：

1. 在某台機器上設定 NFS Server
2. 創建 NFS-based PersistentVolume
3. 所有節點都可以存取相同的資料

## 驗證部署

```bash
# 查看所有資源
sudo k3s kubectl get all -n mcapp -o wide

# 確認資料庫在實驗室機器上
sudo k3s kubectl get pods -n mcapp -l app=db -o wide

# 應該顯示 NODE 欄位為實驗室機器的名稱
```

## 存取應用

由於前端使用 NodePort (30080)，您可以透過任一節點存取：

```bash
# 透過筆電
http://<LAPTOP_IP>:30080

# 透過實驗室機器
http://<LAB_IP>:30080
```

## 安全建議

1. **使用私有網路**：確保 k3s 節點在私有網路中
2. **設定防火牆**：只開放必要的端口
3. **定期更新**：保持 k3s 版本最新
4. **備份 Token**：安全儲存 node-token

## 總結

✅ **可行性**：將資料庫放在實驗室機器上是完全正確且推薦的做法  
✅ **優點**：資源分散、更接近生產環境的架構  
✅ **注意**：需要確保網路連接和適當的節點標籤

這種多節點部署比單節點更能體現 Kubernetes 的優勢！

---

## Windows 用戶專用指南

### 問題：在 Windows 上看到 "Can not find systemd" 錯誤

這是因為 k3s 需要 Linux 系統！以下是 Windows 用戶的解決方案：

### 方案 1: 使用 WSL2（推薦用於學習）

**步驟 1: 安裝 WSL2**
```powershell
# 在 PowerShell (管理員權限) 中執行
wsl --install -d Ubuntu

# 重啟電腦
```

**步驟 2: 進入 WSL2 並安裝 k3s**
```powershell
# 啟動 WSL2
wsl

# 現在您在 Ubuntu Linux 環境中
# 更新套件
sudo apt update

# 安裝 k3s
curl -sfL https://get.k3s.io | sh -

# 等待 k3s 啟動
sleep 10

# 驗證安裝
sudo k3s kubectl get nodes
```

**步驟 3: 部署應用**
```bash
# 在 WSL2 中
cd /mnt/c/Users/emily/Desktop/115_CCSA/HW6/ops
sudo bash deploy-k3s.sh
```

**步驟 4: 從 Windows 存取應用**
```powershell
# 取得 WSL2 IP
wsl hostname -I

# 在 Windows 瀏覽器開啟
# http://<WSL2_IP>:30080
```

**WSL2 限制：**
- ⚠️ WSL2 網路可能需要額外配置
- ⚠️ 每次重啟 WSL2，IP 可能改變
- ⚠️ 不適合生產環境
- ✅ 適合學習和測試

### 方案 2: 直接在實驗室 Linux 機器部署（最推薦）

**優點：**
- ✅ 真實的 Linux 環境
- ✅ 穩定的網路
- ✅ 更接近生產環境
- ✅ 無需在 Windows 上設置

**步驟：**

```bash
# 1. 從 Windows SSH 連接到實驗室機器
ssh your_username@isl3080

# 2. 在實驗室機器上安裝 k3s
curl -sfL https://get.k3s.io | sh -

# 3. 上傳或 git clone 您的專案
git clone https://github.com/b1029009Chien/115_CCSA.git
cd 115_CCSA/HW6

# 4. 部署應用
cd ops
sudo bash deploy-k3s.sh

# 5. 驗證
sudo k3s kubectl get all -n mcapp

# 6. 記下實驗室機器的 IP
hostname -I
```

**從 Windows 存取：**
```
瀏覽器開啟: http://isl3080:30080
或: http://<實驗室機器IP>:30080
```

### 方案 3: WSL2 (Master) + 實驗室機器 (Worker)

如果您想體驗真正的多節點叢集：

**在 Windows WSL2 上（Master）：**
```bash
wsl

# 安裝 k3s server
curl -sfL https://get.k3s.io | sh -

# 取得 token
sudo cat /var/lib/rancher/k3s/server/node-token

# 取得 WSL2 IP
ip addr show eth0 | grep "inet " | awk '{print $2}' | cut -d/ -f1

# 輸出例如: 172.18.xxx.xxx
```

**在實驗室 Linux 機器上（Worker）：**
```bash
# SSH 連接到實驗室機器
ssh your_username@isl3080

# 加入叢集
curl -sfL https://get.k3s.io | K3S_URL=https://<WSL2_IP>:6443 \
  K3S_TOKEN=<TOKEN_FROM_WSL2> sh -
```

**注意網路問題：**
- WSL2 的 IP 通常在 `172.x.x.x` 範圍
- 實驗室機器需要能夠連接到這個 IP
- 可能需要 Windows 防火牆設定
- 如果網路不通，考慮反向配置（實驗室機器當 Master）

### 方案 4: 完全在實驗室機器上（多容器模擬多節點）

如果無法設置真正的多節點，可以在單個 Linux 機器上部署所有服務：

```bash
# SSH 到實驗室機器
ssh your_username@isl3080

# 安裝 k3s
curl -sfL https://get.k3s.io | sh -

# 部署應用（所有服務在同一節點）
cd 115_CCSA/HW6/ops
sudo bash deploy-k3s.sh

# k3s 會自動管理所有 Pod
# 雖然不是多節點，但仍然展示了 Kubernetes 的特性
```

### 常見問題

**Q: 我必須使用 Linux 嗎？**
A: 是的，k3s 需要 Linux。您可以使用 WSL2 (Windows)、虛擬機或實驗室的 Linux 機器。

**Q: Docker Desktop 不行嗎？**
A: Docker Desktop 可以運行 Kubernetes，但這是完整的 Kubernetes，不是 k3s。作業要求使用 k3s。

**Q: 為什麼不能在 Windows 上直接運行？**
A: k3s 依賴 Linux 的系統調用、init 系統（systemd/openrc）和容器運行時，這些在 Windows 上不可用。

**Q: WSL2 和實驗室機器，哪個更好？**
A: 實驗室 Linux 機器更好：
- 真實的 Linux 環境
- 更穩定的網路
- 更好的性能
- 更接近生產環境

### 推薦配置（針對您的情況）

根據您有實驗室 Linux 機器（isl3080）：

```
推薦方案：單節點部署在實驗室機器

┌─────────────────────────────────┐
│  實驗室機器 (isl3080)           │
│  - Linux 系統                   │
│  - k3s (單節點)                 │
│  - Database Pod                 │
│  - Backend Pods (2 replicas)    │
│  - Frontend Pod                 │
└─────────────────────────────────┘
          ↑
          │ HTTP :30080
          │
┌─────────┴───────────────────────┐
│  Windows 筆電                   │
│  - 瀏覽器存取應用               │
│  - SSH 管理 k3s                 │
└─────────────────────────────────┘
```

這樣最簡單、最穩定，也完全符合作業要求！

