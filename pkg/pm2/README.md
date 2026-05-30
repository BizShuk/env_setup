# PM2 — Process Manager 筆記

PM2 是 2013 年誕生的 Node.js 程序管理器，但因為介面現代、儀表板直觀，用起來感覺比同期工具（Supervisor 等）新穎。

關鍵優勢：Mac 和 Ubuntu 都靠 `npm` 安裝，操作指令完全一致，跨兩台機器零學習成本。

> 可以把 PM2 想成一位拿著平板的智慧管家：你把要顧的程式交給他，他負責記錄誰在上班、誰昏倒了要扶起來、隨時給你看每個人的狀態，還幫你保存工作日誌。

---

## 安裝（Mac 與 Ubuntu 通用）

PM2 本身是 Node 寫的，但能管任何語言的程式。

```bash
# 確認 node 與 npm
node -v && npm -v

# 全域安裝
npm install -g pm2
```

---

## 開機自動啟動

這是唯一一個 Mac 和 Ubuntu 有底層差異的地方，但 PM2 幫你自動處理。

```bash
# 1. 啟動好所有服務後存檔
pm2 save

# 2. 產生開機啟動腳本（PM2 自動偵測平台）
pm2 startup
```

| 平台    | PM2 使用的底層機制 |
| ------- | ------------------ |
| Ubuntu  | systemd            |
| macOS   | launchd            |

`pm2 startup` 會印出一行指令要你執行（Ubuntu 上通常需要 `sudo`）。執行後重開機，`pm2 save` 當下存的服務就會自動復活。

> 之後若改了服務清單，記得重新 `pm2 save` 更新存檔。

---

## 執行計畫（Getting Started Checklist）

1. 兩台機器都裝好 Node.js 與 PM2，確認 `pm2 -v` 正常
2. 試水：用 `pm2 start ... --name` 啟動一個服務，跑 `pm2 list`、`pm2 logs`、`pm2 monit`，熟悉核心指令
3. 復活測試：`kill <PID>` 故意殺掉服務，確認重啟次數 +1 且狀態回到 `online`
4. 裝 `pm2-logrotate`，設好保留策略，做塞爆測試驗證輪替有效 → 見 [log-management.md](log-management.md)
5. 把所有服務寫進 `ecosystem.config.js`，跑 `pm2 save` 與 `pm2 startup` → 見 [ecosystem.md](ecosystem.md)
6. 把 `ecosystem.config.js` 放進 git，Mac 和 Ubuntu 兩台機器共用同一份設定

---

## 相關筆記

- [commands.md](commands.md) — 指令速查表（狀態管理、啟動、重啟）
- [log-management.md](log-management.md) — 日誌監控與輪替設定
- [ecosystem.md](ecosystem.md) — Ecosystem 設定檔與範例
