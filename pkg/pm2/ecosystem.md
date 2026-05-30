# PM2 Ecosystem 設定檔

當服務超過兩三個，用設定檔統一管理，比每次打一長串指令更清晰、可維護。

---

## 產生範本

```bash
pm2 ecosystem    # 產生 ecosystem.config.js 範本
```

---

## 設定檔範例

```javascript
module.exports = {
  apps: [
    {
      name: "my-api",
      script: "app.js",
      max_memory_restart: "300M",
    },
    {
      name: "my-worker",
      script: "worker.py",
      interpreter: "python3",
      cron_restart: "0 3 * * *",
    },
  ],
};
```

---

## 常用欄位

| 欄位                  | 說明                                     | 範例                  |
| --------------------- | ---------------------------------------- | --------------------- |
| `name`                | 服務名稱（操作時用來識別）               | `"my-api"`            |
| `script`              | 入口檔案或執行檔路徑                     | `"app.js"`            |
| `interpreter`         | 直譯器（Node 以外的語言需指定）          | `"python3"`           |
| `max_memory_restart`  | 記憶體超過此值就重啟（防 memory leak）   | `"300M"`              |
| `cron_restart`        | 定時重啟（cron 語法）                    | `"0 3 * * *"`         |
| `watch`               | 監看檔案變動就重啟（開發用）             | `true`                |
| `env`                 | 環境變數                                 | `{ NODE_ENV: "production" }` |

---

## 使用方式

```bash
pm2 start ecosystem.config.js     # 一次啟動所有服務
pm2 restart ecosystem.config.js   # 一次重啟所有服務
```

---

## 為什麼要納入版控

- 換機器或重建環境時，直接 `pm2 start ecosystem.config.js` 就還原全部服務
- Mac 和 Ubuntu 兩台機器共用同一份設定，零差異
- 這是專業部署的標準做法
