# macOS Static IP Suggestion Design

## 目標

執行 `bin/mac/mac_static_ip.sh` 的 `status`（包含無參數執行）時，除了顯示目前網路服務資訊，也產生一個依目前 IPv4 網路資訊計算的固定 IP 建議指令。

## 行為

- 解析 `networksetup -getinfo <service>` 的目前 IPv4、subnet mask 與 router。
- 依 subnet mask 計算 network、broadcast 與可用 host 位址，排除 network/broadcast。
- 將可用 host 依序分成兩個建議區間：`25%–50%` 與 `75%–100%`。
- 以等機率選擇其中一個區間，再從該區間隨機選一個 IPv4。
- 輸出可複製的 `mac_static_ip.sh set` 指令，不帶 `--yes`，保留既有確認流程。
- DNS 沿用目前設定；若服務沒有手動 DNS，使用 router 作為指令中的 DNS fallback。
- 同時輸出兩個完整候選區間，並提醒使用者先確認位址未被使用，最好在路由器設定 DHCP reservation。

## 邊界與錯誤處理

- `/31`、`/32` 或無法取得目前 IPv4、subnet mask、router 時，不產生建議指令，輸出可理解的原因後保留原本 status 結果。
- 建議候選範圍以可用 host 數量計算；小型子網路的百分比邊界以向上取整的起點與向下取整的終點處理。
- 現有 `set`、`dhcp`、`services` 行為維持不變。

## 實作邊界

- 使用現有 `networksetup`，不額外依賴 `ipconfig` 或 `route`。
- IPv4 轉整數與整數轉 IPv4 以可獨立測試的 Bash 函式實作。
- 隨機來源使用 macOS 可用的 `/dev/urandom`。

## 驗證

- 先新增會失敗的 shell 測試，覆蓋 `/24` 的兩段範圍與建議指令組合。
- 再實作最小變更使測試通過。
- 執行 shell 語法檢查、測試，以及在非 macOS 環境確認腳本仍正確拒絕執行。
