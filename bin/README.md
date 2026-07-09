# `bin/` — 可執行入口索引 (Entry Point Index)

`bin/` 內所有檔案已透過 `bin/bash/settings.sh` 軟連結到 `~/bin`, 任何子目錄的工具皆可直接以 bare name 呼叫 (例：`mac_cleanup.sh`、`system_info`)。

## 目錄分區 (Areas)

| Area         | 用途                                              | 範例入口                                                       |
| ------------ | ------------------------------------------------- | -------------------------------------------------------------- |
| `bin/bash/`  | dotfiles、`settings.sh`、vim 設定、bash alias     | `settings.sh`、`.bashrc`、`.vimrc`                             |
| `bin/mac/`   | macOS 專屬稽核與清理                              | `mac_cleanup.sh`、`disk_analysis-mac.sh`                       |
| `bin/network/`| 跨平台網路掃描 (traceroute + nmap)              | `scan_network.sh`                                              |
| `bin/system/`| 跨平台硬體與系統偵測                              | `system_info`、`checkdisk`、`myip`                             |
| `bin/vscode/`| VSCode / Antigravity IDE 設定                     | `settings.json`、`keybindings.json`                            |
| 根目錄 helper | 開發者輔助小工具 (見 `docs/bin_index.md` 完整索引) | `json`、`listen_port`                                          |

## 慣例 (Conventions)

### 工具命名 (Naming)

- 新工具加入 `bin/<area>/<tool>`, 需要 root-level 入口時在 `bin/<tool>` 加 symlink
- macOS 工具統一加 `mac_` 前綴與 `.sh` 後綴 (例：`mac_cleanup.sh`, `disk_analysis-mac.sh`)

### 共用 helper 慣例 (Shared Helpers)

- 跨腳本共用函式 / 樣板 / 常數, 放至 `bin/<area>/_lib_<purpose>.sh`
- 使用方式: `source "$(dirname "$0")/_lib_<purpose>.sh"`
- 範例: `bin/mac/_lib_audit.sh` 提供 macOS 稽核腳本共用的 `term_log` / `md_log` / `log` / `header` / `audit_init`

### 環境變數入口 (Settings)

- 所有腳本 `source "$(dirname "$0")/../bash/settings.sh"` 取得 `REPO_DIR`, `REPO_SCRIPTS`, `OS`, `ARCH`
- 私密值 (`passwd` / `email` / API token) 一律讀 `~/.config/env_setup/settings.private.sh` 或 `~/.bash_local`

### 排程註冊 (Scheduling)

- pm2 任務以 `./bin/<area>/<tool>` 全路徑註冊於 `ecosystem.config.js`

完整索引與描述見 [docs/bin_index.md](../docs/bin_index.md)
