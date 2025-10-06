根據你的專案目標與憲章，這是建議的任務分解清單：

---

## HW4 Name Database 開發任務清單

### 1. 專案基礎設置
- [x] 建立 LICENSE、README.md、QUICKSTART.md、CONTRIBUTING.md、CHANGELOG.md
- [x] 建立 Spec、ai-log 資料夾
- [x] 準備 Docker Compose（Nginx + Flask + SQLite）

### 2. 後端（Flask）
- [ ] 設計資料庫 schema（姓名表）
- [ ] 實作 repository pattern 或 ORM 抽象層
- [ ] API：新增姓名
- [ ] API：列出所有姓名
- [ ] API：刪除姓名
- [ ] 撰寫單元測試（pytest）
- [ ] 撰寫整合測試
- [ ] 測試覆蓋率達 90% 以上

### 3. 前端（Nginx + HTML）
- [ ] 設計簡易前端頁面（index.html）
- [ ] 連接 API，實現新增、查詢、刪除姓名功能

### 4. 程式碼品質
- [ ] 設定 flake8、black 靜態分析與格式化
- [ ] 撰寫必要註解與文件

### 5. CI/CD
- [ ] 設定 GitHub Actions 或其他 CI 工具
- [ ] PR 必須通過自動化測試與靜態分析

### 6. 文件與交付
- [ ] 完善 API、模組、邏輯說明文件
- [ ] 準備 tgz 封裝腳本（可選）

---

如需自動產生任務追蹤表、issue 樣板或進一步細化，請告知！