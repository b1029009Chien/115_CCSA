# HW4 Name Database System

本專案是一個三層架構（Nginx + Flask + SQLite）的姓名資料庫系統，支援姓名新增、查詢、刪除。

## 架構
- 前端：Nginx 反向代理 + 靜態 HTML
- 後端：Flask (Python 3.10+)
- 資料庫：SQLite

## 如何執行
請參考 `QUICKSTART.md`。

## 如何測試
1. 進入 backend 容器：`docker compose exec backend bash`
2. 執行 `pytest` 進行測試

## 主要功能
- 新增姓名
- 列出所有姓名
- 刪除姓名

---

MIT License