根據你的憲章與專案目標，這是建議的開發與交付計畫：

---

## HW4 Name Database 專案開發計畫

### 1. 專案結構與基礎設置
- 建立三層架構（Nginx + Flask + SQLite）
- 完善專案目錄（Spec、ai-log、README、LICENSE、QUICKSTART、CONTRIBUTING、CHANGELOG）

### 2. 開發流程（TDD）
- 先撰寫單元測試與整合測試（pytest）
- 再實作三大功能：
  1. 新增姓名
  2. 列出所有姓名
  3. 刪除姓名

### 3. 程式碼品質與維護
- 強制使用 flake8、black 進行靜態分析與格式化
- 所有資料庫操作經 repository pattern 或 ORM，防止 SQL injection
- 僅允許 requirements.txt 內套件
- 嚴格區分測試資料與正式資料

### 4. CI/CD 與自動化
- 設定 GitHub Actions 或其他 CI 工具
- 每次 PR 必須通過自動化測試與靜態分析
- 測試覆蓋率目標 90% 以上

### 5. 文件與審查
- 完善 API、模組、邏輯註解與文件
- PR 需經至少一位成員審查
- 重大變更需附設計說明與測試計畫

### 6. 交付與封裝
- 提供可直接運行的 Docker Compose
- 專案可一鍵打包為 tgz，方便 GitHub 發布

---

如需詳細任務分解、CI/CD 腳本或測試範例，請再告知！