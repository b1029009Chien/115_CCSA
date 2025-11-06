# HW6 k3s Quick Reference

## 快速部署步驟

```bash
# 1. 初始化 k3s
cd HW6/ops
sudo bash init-k3s.sh

# 2. 部署應用
sudo bash deploy-k3s.sh

# 3. 驗證部署
sudo bash verify-k3s.sh

# 4. 存取應用
# 開啟瀏覽器訪問: http://localhost:30080
```

## 常用指令速查

### 查看狀態
```bash
# 查看所有資源
sudo k3s kubectl get all -n mcapp

# 查看 Pods
sudo k3s kubectl get pods -n mcapp

# 查看 Services
sudo k3s kubectl get services -n mcapp

# 查看 Deployments
sudo k3s kubectl get deployments -n mcapp

# 查看 StatefulSets
sudo k3s kubectl get statefulsets -n mcapp

# 查看 PVC
sudo k3s kubectl get pvc -n mcapp
```

### 查看日誌
```bash
# 查看後端 API 日誌
sudo k3s kubectl logs -n mcapp -l app=api -f

# 查看前端日誌
sudo k3s kubectl logs -n mcapp -l app=web -f

# 查看資料庫日誌
sudo k3s kubectl logs -n mcapp -l app=db -f

# 查看特定 Pod 日誌
sudo k3s kubectl logs -n mcapp <pod-name> -f
```

### 除錯指令
```bash
# 描述資源詳情
sudo k3s kubectl describe pod -n mcapp <pod-name>
sudo k3s kubectl describe deployment -n mcapp api
sudo k3s kubectl describe service -n mcapp web

# 進入 Pod 執行指令
sudo k3s kubectl exec -it -n mcapp <pod-name> -- /bin/bash

# 連接資料庫
sudo k3s kubectl exec -it -n mcapp db-0 -- psql -U postgres -d appdb

# Port forwarding
sudo k3s kubectl port-forward -n mcapp service/web 8080:80
```

### 擴展應用
```bash
# 擴展後端 API
sudo k3s kubectl scale deployment api -n mcapp --replicas=3

# 擴展前端
sudo k3s kubectl scale deployment web -n mcapp --replicas=2

# 查看擴展狀態
sudo k3s kubectl get pods -n mcapp -w
```

### 更新部署
```bash
# 更新映像檔
sudo k3s kubectl set image deployment/api -n mcapp api=chien314832001/hw5_api:latest

# 重新部署
sudo k3s kubectl rollout restart deployment/api -n mcapp

# 查看部署狀態
sudo k3s kubectl rollout status deployment/api -n mcapp

# 查看部署歷史
sudo k3s kubectl rollout history deployment/api -n mcapp
```

### 測試 API
```bash
# 健康檢查
curl http://localhost:30080/api/health

# 取得所有名稱
curl http://localhost:30080/api/names

# 新增名稱
curl -X POST http://localhost:30080/api/names \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Name"}'

# 刪除名稱
curl -X DELETE http://localhost:30080/api/names/1
```

### 清理
```bash
# 僅移除應用
cd HW6/ops
sudo bash cleanup-k3s.sh

# 移除應用並卸載 k3s
sudo bash cleanup-k3s.sh --uninstall-k3s
```

## 資源限制 (可選)

若要為 Pod 設定資源限制，可以編輯 manifest 檔案：

```yaml
# backend.yaml 範例
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

然後重新部署：
```bash
sudo k3s kubectl apply -f content/k3s/backend.yaml
```

## 監控指令

```bash
# 即時查看 Pod 狀態
sudo k3s kubectl get pods -n mcapp -w

# 查看 Pod 資源使用
sudo k3s kubectl top pods -n mcapp

# 查看節點資源使用
sudo k3s kubectl top nodes

# 查看事件
sudo k3s kubectl get events -n mcapp --sort-by='.lastTimestamp'
```

## 故障排除

### Pod 一直在 Pending 狀態
```bash
# 檢查 Pod 事件
sudo k3s kubectl describe pod -n mcapp <pod-name>

# 檢查 PVC 狀態
sudo k3s kubectl get pvc -n mcapp
```

### Pod 一直重啟
```bash
# 查看 Pod 日誌
sudo k3s kubectl logs -n mcapp <pod-name> --previous

# 查看 Pod 狀態詳情
sudo k3s kubectl describe pod -n mcapp <pod-name>
```

### 無法連接資料庫
```bash
# 檢查資料庫 Pod 狀態
sudo k3s kubectl get pods -n mcapp -l app=db

# 查看資料庫日誌
sudo k3s kubectl logs -n mcapp db-0

# 從 API Pod 測試連接
API_POD=$(sudo k3s kubectl get pod -n mcapp -l app=api -o jsonpath='{.items[0].metadata.name}')
sudo k3s kubectl exec -n mcapp $API_POD -- nc -zv db 5432
```

### 服務無法存取
```bash
# 檢查 Service
sudo k3s kubectl get svc -n mcapp

# 檢查 Endpoints
sudo k3s kubectl get endpoints -n mcapp

# 檢查 Ingress
sudo k3s kubectl get ingress -n mcapp
```

## kubectl 別名設定 (可選)

為了方便使用，可以設定別名：

```bash
# 加入到 ~/.bashrc 或 ~/.zshrc
alias k='sudo k3s kubectl'
alias kn='sudo k3s kubectl -n mcapp'

# 使用別名
k get nodes
kn get pods
kn logs -l app=api -f
```

## 進階操作

### 備份資料庫
```bash
# 從資料庫 Pod 匯出資料
sudo k3s kubectl exec -n mcapp db-0 -- pg_dump -U postgres appdb > backup.sql
```

### 還原資料庫
```bash
# 匯入資料到資料庫 Pod
cat backup.sql | sudo k3s kubectl exec -i -n mcapp db-0 -- psql -U postgres appdb
```

### 查看 k3s 系統 Pods
```bash
sudo k3s kubectl get pods -n kube-system
```

### 重啟特定 Pod
```bash
sudo k3s kubectl delete pod -n mcapp <pod-name>
# Pod 會自動重建
```
