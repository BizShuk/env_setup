# `bin/system/` — 跨平台硬體與系統偵測 (Cross-Platform Hardware & System Probe)

本目錄提供本機硬體與系統狀態的細粒度偵測工具, 透過 `system_profiler` (macOS) 或 `lshw` / `lsblk` (Linux) 取出對應章節, 印至 stdout。

## 細粒度偵測 (`*_info` 工具)

| 工具             | 偵測內容                              |
| ---------------- | ------------------------------------- |
| `os_info`        | 作業系統版本、核心、架構              |
| `cpu_info`       | CPU 型號、核心數、執行緒              |
| `mem_info`       | 記憶體大小與使用率                    |
| `gpu_info`       | 顯示卡型號與驅動                      |
| `disk_info`      | 磁碟與分割區                          |
| `display_info`   | 顯示器解析度與連接介面                |
| `usb_info`       | USB 裝置列舉                          |
| `input_info`     | 鍵盤/滑鼠/觸控板等輸入裝置            |
| `audio_info`     | 音訊裝置 (輸入/輸出)                   |
| `myip`           | 本機對外 IP                            |

## 聚合入口 (Aggregate Entry)

- `system_info`: 一次跑完上述 10 個 sub-tool。
- `system_dump`: 進一步把 `brew bundle dump` / `vscode_extension_dump` / `agy-ide_extension_dump` 的輸出彙整成 dump 檔。
- `checkdisk`: 磁碟使用率。
- `list_big_files.sh`: 大檔掃描 (top N)。
- `network_topology_scan.sh`: traceroute + nmap 拓樸掃描 (由 `bin/network/scan_network.sh --mode=topology` 呼叫)。

## 套件與組態 (Packages & Config)

- `brew_bundle_dump`: 匯出 `Brewfile`。
- `system_performance.sh`: 性能檢測 cheatsheet (symlink broken, 待修)。
- `config/`: pf 防火牆樣板等。

## macOS 安全性建議

> macOS 專屬稽核腳本位於 `bin/mac/` (見 `bin/mac/`), 包含 `disk_analysis-mac.sh` / `launch_audit-mac.sh` / `login_audit-mac.sh` / `network_security_audit-mac.sh`。本目錄 `bin/system/` 不含 macOS 稽核工具, 僅提供跨平台硬體/系統偵測。
本目錄提供本機硬體與系統狀態的細粒度偵測工具, 透過 `system_profiler` (macOS) 或 `lshw` / `lsblk` (Linux) 取出對應章節, 印至 stdout。

## 細粒度偵測 (`*_info` 工具)

| 工具             | 偵測內容                              |
| ---------------- | ------------------------------------- |
| `os_info`        | 作業系統版本、核心、架構              |
| `cpu_info`       | CPU 型號、核心數、執行緒              |
| `mem_info`       | 記憶體大小與使用率                    |
| `gpu_info`       | 顯示卡型號與驅動                      |
| `disk_info`      | 磁碟與分割區                          |
| `display_info`   | 顯示器解析度與連接介面                |
| `usb_info`       | USB 裝置列舉                          |
| `input_info`     | 鍵盤/滑鼠/觸控板等輸入裝置            |
| `audio_info`     | 音訊裝置 (輸入/輸出)                   |
| `myip`           | 本機對外 IP                            |

## 聚合入口 (Aggregate Entry)

- `system_info`: 一次跑完上述 10 個 sub-tool。
- `system_dump`: 進一步把 `brew bundle dump` / `vscode_extension_dump` / `agy-ide_extension_dump` 的輸出彙整成 dump 檔。
- `checkdisk`: 磁碟使用率。
- `list_big_files.sh`: 大檔掃描 (top N)。
- `network_topology_scan.sh`: traceroute + nmap 拓樸掃描 (與 `bin/scan_private_network` / `bin/scan_target_network` 整合中, 見 `plans/2026-07-08`)。

## 套件與組態 (Packages & Config)

- `brew_bundle_dump`: 匯出 `Brewfile`。
- `system_performance.sh`: 性能檢測 cheatsheet (symlink broken, 待修)。
- `config/`: pf 防火牆樣板等。

## macOS 安全性建議

> macOS 專屬稽核腳本位於 `bin/mac/` (見 `bin/mac/`), 包含 `disk_analysis-mac.sh` / `launch_audit-mac.sh` / `login_audit-mac.sh` / `network_security_audit-mac.sh`。本目錄 `bin/system/` 不含 macOS 稽核工具, 僅提供跨平台硬體/系統偵測。
