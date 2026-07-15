# pkg/mac — macOS 樣板與設定樣本

`pkg/mac/` 裝載 macOS 專用樣板資源, 給 `bin/mac/` 內工具 (cleanup / audit / keyboard shortcuts / launch 稽核) 使用。

## 內容

| 路徑                  | 用途                                                            |
| --------------------- | --------------------------------------------------------------- |
| `setup.sh`            | macOS 初始化入口                                                |
| `globalp.plist`       | 全域偏好 defaults 樣板                                          |
| `LaunchAgents/`       | launchd plist 樣板                                              |
| `applescript/`        | AppleScript 腳本 (e.g. `toggleFn.scpt`)                         |

## macOS 設定備份 / 還原檢查表

完整 macOS 系統設定備份與還原的 `defaults` 命令檢查表, 見：

[`specs/2026-07-15-macos-backup-checklist.md`](../../specs/2026-07-15-macos-backup-checklist.md)

該檔早期版本於 Phase 1 之前曾以 inline 形式塞於本目錄的 `README.backup.md` (59KB),
對單一 git diff 不友善、亦不易被新協作者定位。Phase 7.5 之後改為獨立 spec,
本 README 僅保留目錄簡介與參照。

## 加入流程 (Add New Template)

1. macOS 相關樣板放於本目錄
2. 腳本或工具入口放於 `bin/mac/<tool>.sh`
3. 大型靜態文件 (例如備份清單) 改放到 `specs/YYYY-MM-DD-<topic>.md`, 本 README 用相對路徑 reference
4. 若需排程, 在 `ecosystem.config.js` 用 `./bin/mac/<tool>` 全路徑註冊
