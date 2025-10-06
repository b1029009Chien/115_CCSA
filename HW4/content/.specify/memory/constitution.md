## Core Principles

### I. 單一職責原則（Single Responsibility Principle）
每個模組/函式僅負責一項明確任務（如：新增姓名、列出姓名、刪除姓名）。

### II. 可測試性（Testability）
所有功能（新增、查詢、刪除姓名）必須有單元測試與整合測試，測試覆蓋率目標 90% 以上。

### III. 持續整合與靜態分析（CI & Static Analysis）
所有程式碼變更必須通過自動化測試與靜態分析（如 flake8、black、pytest）。

### IV. 易於維護與擴充（Maintainability & Extensibility）
程式碼需模組化、結構清晰，並有完整註解與文件，便於日後維護與功能擴充。

### V. 資料一致性與安全性（Data Consistency & Security）
所有資料庫操作需防止 SQL injection，並確保資料一致性。

## 額外約束（Additional Constraints）

- 僅允許使用明確列於 requirements.txt 的套件。
- 必須使用 Python 3.10+。
- 所有資料庫操作需經過抽象層（如 ORM 或 repository pattern）。
- 測試資料與正式資料需嚴格分離。

## 開發流程（Development Workflow）

- 所有功能（新增、查詢、刪除姓名）需先撰寫測試再實作（TDD）。
- 每次提交必須通過所有自動化測試與靜態分析。
- Pull Request 需經至少一位成員審查。
- 重大變更需附設計說明與測試計畫。

## Governance
本憲章優先於其他開發慣例。任何修訂需經團隊討論、文件化並制定遷移計畫。所有 PR 必須驗證符合本憲章規範。

**Version**: 1.0.0 | **Ratified**: 2025-10-06 | **Last Amended**: 2025-10-06
<!-- Version: 1.0.0 | Ratified: 2025-10-06 | Last Amended: 2025-10-06 -->