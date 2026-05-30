# PM2 日誌監控與保留

PM2 自動幫每個服務存兩份日誌，預設位置：`~/.pm2/logs/`

| 日誌類型   | 檔名格式              |
| ---------- | --------------------- |
| 標準輸出   | `<name>-out.log`      |
| 錯誤輸出   | `<name>-error.log`    |

---

## 即時查看日誌

```bash
pm2 logs                      # 串流顯示所有服務的即時日誌
pm2 logs my-api               # 只看某個服務
pm2 logs my-api --lines 200   # 先顯示最後 200 行
pm2 logs --err                # 只看錯誤日誌
```

> `pm2 logs` 是 debug 時最常用的指令，畫面持續滾動更新，像即時翻閱工作日誌本。

---

## 即時資源監控儀表板

```bash
pm2 monit
```

開一個終端機儀表板，同時顯示每個服務的 CPU、記憶體用量和即時日誌。像一面 CCTV 監控牆，這也是 PM2 比 Supervisor 體驗好很多的地方。

---

## 清理日誌

```bash
pm2 flush            # 清空所有日誌內容
pm2 flush my-api     # 只清某個服務的日誌
```

---

## 日誌輪替（Log Rotation）

PM2 預設不自動清理舊日誌，**一定要裝 `pm2-logrotate`**，否則日誌會無限長大、塞爆硬碟。

```bash
# 安裝官方日誌輪替模組
pm2 install pm2-logrotate

# 設定策略
pm2 set pm2-logrotate:max_size 10M               # 單檔超過 10MB 就輪替
pm2 set pm2-logrotate:retain 7                   # 最多保留 7 份舊檔
pm2 set pm2-logrotate:compress true              # 舊檔壓縮成 .gz 省空間
pm2 set pm2-logrotate:rotateInterval '0 0 * * *' # 每天午夜也輪替一次
```

設定好後會自動歸檔、壓縮、銷毀過舊的日誌，不需要手動管理。
