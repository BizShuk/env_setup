# PM2 指令速查表

## 啟動 Daemon（不限語言）

```bash
# Node
pm2 start app.js --name my-api

# Python
pm2 start worker.py --interpreter python3 --name my-worker

# Shell 腳本
pm2 start ./run.sh --name my-job

# 執行檔（Go build 出來的 binary 等）
pm2 start ./mybinary --name my-service
```

> `--name` 非常重要：之後所有操作都靠這個名字。沒命名 PM2 會用檔名，多個服務容易混淆。

---

## 狀態查看

```bash
pm2 list              # 總覽表格：名稱、狀態、CPU、記憶體、重啟次數、運行時間
pm2 status            # 同 list
pm2 describe my-api   # 單一服務完整細節（路徑、PID、log 位置等）
```

### status 欄位說明

| 狀態        | 意義                                     |
| ----------- | ---------------------------------------- |
| `online`    | 運行中（正常）                           |
| `stopped`   | 手動停止                                 |
| `errored`   | 程式當掉且重啟也救不回來，需查日誌        |
| `launching` | 啟動中                                   |

> `↺ restart`（重啟次數）異常飆高 → 程式一直當掉又被救起 → 通常有 bug，去查日誌。

---

## 基本操作

```bash
pm2 stop my-api       # 停止（保留在清單裡，可 restart 回來）
pm2 restart my-api    # 重啟（短暫中斷）
pm2 reload my-api     # 平滑重啟（zero-downtime，主要對 Node cluster 有效）
pm2 delete my-api     # 從清單移除（要重新 pm2 start 才會回來）
pm2 restart all       # 一次重啟全部
```

| 操作       | 比喻                                   |
| ---------- | -------------------------------------- |
| `stop`     | 員工請假，名冊還在，可隨時 `restart`   |
| `delete`   | 解雇，從名冊移除，需重新 `pm2 start`   |

---

## 自動重啟條件

PM2 預設在程式當掉時就會自動重啟（取代 `nohup &` 的核心價值）。可加條件：

```bash
# 記憶體超過 300MB 就重啟（防 memory leak）
pm2 start app.js --name my-api --max-memory-restart 300M

# 監看檔案變動就重啟（開發用，正式環境不建議）
pm2 start app.js --name my-api --watch

# 每天凌晨 3 點定時重啟（cron 語法）
pm2 start app.js --name my-api --cron-restart="0 3 * * *"
```
