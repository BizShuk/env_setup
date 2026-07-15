# env_setup — 技術脈絡 (Technical Context)

## 專案結構 (Project Structure)

```text
.
├── LICENSE
├── README.md
├── CLAUDE.md
├── AGENTS.md -> CLAUDE.md
├── README.todo
├── run.sh                         # 唯一 symlink 入口 + IDE profile 套用
├── ecosystem.config.js            # pm2 cron + 常駐任務
├── go.mod / go.sum                # macbackup Go module (module github.com/bizshuk/env_setup)
├── main.go                        # macbackup 組合根 (composition root)
├── build.sh                       # go build -> ~/.local/bin/macbackup
├── cmd/backup/                    # macbackup 命令層 (CLI command list)
├── svc/backup/                    # macbackup 服務層 (與 macOS defaults/plutil 互動 + 邏輯)
├── .geminiignore -> .gitignore
├── .gitmodules                    # 10 個 vim 插件 + libgit2
├── .vscode/                       # repo 自身 VSCode 設定
├── bin/
│   ├── bash/                      # dotfiles + settings.sh + helper
│   │   ├── settings.sh            # 共用環境變數 (USER_BIN, REPO_DIR...)
│   │   ├── .bashrc / .bash_aliases / .bash_function / .bash_logout
│   │   ├── .gitconfig / .gitmessage / .gitignore
│   │   ├── .vimrc / .vim/         # 內含 10 個 git submodules
│   │   ├── .screenrc / .toprc / .npmrc
│   │   ├── backup.ignore
│   │   ├── cmd_usage.md           # 個人 cheat notes
│   │   └── shell_script_sample.sh
│   ├── mac/                       # macOS 專用工具
│   │   ├── mac_cleanup
│   │   ├── disk_analysis-mac.sh / launch_audit-mac.sh
│   │   ├── login_audit-mac.sh / network_security_audit-mac.sh
│   │   ├── mac_keyboard_shortcuts_dump.sh / mac_keyboard_shortcuts_restore.sh
│   │   ├── mac_keyboard_shortcuts_dump.sh / mac_keyboard_shortcuts_restore.sh
│   │   ├── mac_extension_list
│   │   ├── lib.py / ls_sys_path.py
│   │   └── keyboard_shortcuts/    # plist 樣板
│   ├── system/                    # 跨平台系統工具
│   │   ├── system_info            # 聚合 10 個 *_info + myip
│   │   ├── system_dump            # 統一匯出套件清單
│   │   ├── os_info / cpu_info / mem_info / gpu_info / disk_info
│   │   ├── display_info / usb_info / input_info / audio_info
│   │   ├── myip / checkdisk
│   │   ├── list_big_files.sh / network_topology_scan.sh
│   │   ├── brew_bundle_dump / raspi-config / system_service
│   │   ├── system_performance.sh
│   │   ├── config/                # pf 防火牆樣板等
│   │   └── README.md              # 標題錯置 (標記修正)
│   ├── vscode/                    # IDE 設定 + dump/restore
│   │   ├── settings.json / keybindings.json
│   │   ├── snippets/
│   │   ├── agy-ide_extension_install / agy-ide_extension_dump
│   │   ├── vscode_extension_dump
│   │   ├── agy-ide_extension_list.txt / vscode_extension_list.txt
│   │   └── README.md
│   ├── 根目錄 helper (23 個)     # 詳見 plans/2026-07-08 §2.6
│   │   ├── json / git_signing / find_symbolic_link
│   │   ├── iconv_big5_utf8 / file_encoding / reverse_ln
│   │   ├── check_alive / check_service / listen_port
│   │   ├── generate_https_cert / generator_pem.sh
│   │   ├── backup / backupSync
│   │   ├── ssoLogin.sh / ssoLogin_faas.sh
│   │   ├── claudew / claudem / goswitch
│   │   ├── bytedance_setup.sh     # ⚠️ 含明文密碼, 預計刪除
│   │   ├── ssh_config / sshd_config / ssh_keygen / ssh_key_compare
│   │   ├── ssh.md
│   │   ├── strip-docker-image-README.md
│   │   └── settings.sh
├── scripts/                       # OS / tool installer
│   ├── mac.sh / ubuntu.sh
│   ├── bash_env_setup.sh          # dotfile 軟連結入口
│   ├── bash.sh / settings.sh      # scripts 內部 settings
│   ├── brew.sh                    # Homebrew 5.0.3 安裝
│   ├── go.sh                      # Go 1.26.3 + golangci-lint
│   ├── nodejs.sh / nodejs.md
│   ├── openssl_setup.sh / openssl_mac_setup.sh / openssl.cnf / openssl.md
│   ├── ctags_setup.sh
│   ├── git-secret.sh / git.sh / git.md
│   ├── vim.sh / vim.md
│   ├── webmin.sh
│   ├── Brewfile
│   ├── disk/
│   └── README.md
├── pkg/                           # 第三方 source + 樣板
│   ├── ctags-5.8/                 # ⚠️ vendored, 2.2MB / 111 檔
│   ├── libgit2.sh                 # libgit2 helper
│   ├── mac/
│   │   ├── setup.sh / globalp.plist
│   │   ├── LaunchAgents/          # plist 樣板
│   │   └── applescript/           # toggleFn.scpt
│   ├── linux/
│   │   ├── Linux_kernel_structure.png
│   │   ├── notes/                 # 7 份 ubuntu 學習筆記
│   │   └── rc.local
│   ├── sysctl/                    # sysctl.conf / security / pam.d 樣板
│   └── ufw/                       # ufw / user.rules 樣板 (未使用)
├── plans/                         # 進行中計畫
│   ├── 2026-05-22-improve-workspace.md     (ARCHIVED)
│   ├── 2026-05-24-improve-workspace.md     (ARCHIVED)
│   ├── 2026-07-08-env-setup-structural-cleanup.md
│   └── implementation_plan.md
├── specs/
│   ├── 20260217-fix-agent-symlink.md
│   └── 20260218-monitoring-system-update.md (OUT_OF_SCOPE)
├── docs/                          # (規劃新增, 見 plans/2026-07-08)
├── troubleshooting/               # 故障排除腳本
│   ├── exfat.sh / Transcend.sh
│   ├── usb_disk.md / ubuntu_build_error.md
│   └── image/
├── tmp/                           # run.sh 軟連結目標 (唯一)
├── log/                           # 應用日誌
└── config/                        # 歷史殘留 (system_link 舊目標, 已棄用)
```

- **`bin/bash/settings.sh` 為唯一環境變數入口**：所有腳本 `source settings.sh` 取得 `USER_BIN`、`REPO_DIR`、`REPO_SCRIPTS`、`OS`、`ARCH`、`KERNEL_NAME` 等；個人敏感值 (`passwd`/`email`/`token`) 改由 `~/.config/env_setup/settings.private.sh` 提供 (git-ignored)。
- **`bin/bash/settings.sh` 為唯一環境變數入口**：所有腳本 `source settings.sh` 取得 `USER_BIN`、`REPO_DIR`、`REPO_SCRIPTS`、`OS`、`ARCH`、`KERNEL_NAME` 等；個人敏感值 (`passwd`/`email`/`token`) 改由 `~/.config/env_setup/settings.private.sh` 提供 (git-ignored)。

## 技術棧 (Tech Stack)

- Language: Bash/Shell (主要)、Python (輔助, `bin/mac/lib.py` / `ls_sys_path.py`)、AppleScript (`pkg/mac/applescript/toggleFn.scpt`)
- Framework: 無 (純 shell + python 工具集)
- Build tool: `bash` (直接執行) / `wget` / `curl` 安裝 Go toolchain
- Key dependencies:
    - `homebrew 5.0.3` (`scripts/brew.sh`)
    - `go 1.26.3` + `golangci-lint v1.64.5` (`scripts/go.sh`)
    - `traceroute` / `nmap` (網路掃描前置)
    - `system_profiler` (macOS 硬體偵測)
    - `lshw` / `lsblk` (Linux 硬體偵測)
    - `pm2` (`go install github.com/bizshuk/pm2@master`)
    - `cc-plugin` skills (`go install github.com/bizshuk/skills@master`)

## 關鍵決策 (Key Decisions)

- **`bin/bash/settings.sh` 為唯一環境變數入口**：所有腳本 `source settings.sh` 取得 `USER_BIN`、`REPO_DIR`、`REPO_SCRIPTS`、`OS`、`ARCH`、`KERNEL_NAME` 等；個人敏感值 (`passwd`/`email`/`token`) 改由 `~/.config/env_setup/settings.private.sh` 提供 (git-ignored)。
- **`~/bin` symlink 到 `bin/`**：在 `settings.sh` 內 `[ ! -e "$USER_BIN" ] && ln -s "$USER_PROJECT/env_setup/bin" "$USER_BIN"`，新工具直接落入 `bin/<area>/<tool>` 即可被 `PATH` 找到。
- **IDE profile 由 `run.sh` 依 OS 雙綁**：同時把 `bin/vscode/{settings,keybindings,snippets}` 連結到 VSCode (`Code/User`) 與 Antigravity IDE 的 `User/` 目錄。
- **pm2 為唯一排程器**：`ecosystem.config.js` 集中所有 cron 與常駐任務，namespace = `Local`；新增任務以 `./bin/<area>/<tool>` 全路徑註冊。
- **macOS 稽核與硬體偵測分流**：`bin/mac/` 為 macOS 專屬 (`mac_cleanup.sh`、`*_audit-mac.sh`)；`bin/system/` 為跨平台硬體偵測 (`*_info`、`system_info`)。`bin/system/README.md` 目前標題錯置需修正。
- **原則上不引入 Go/Cobra 框架**：本 repo 以純 shell + python 工具集為主，不混用 binary CLI。唯一例外為 repo root 的 macbackup Go module(macOS 設定 backup/import 工具)：因需 gosdk config 慣例路徑 (`~/.config/env_setup/data/`) 與逐一 diff/確認的互動邏輯,以 Go 實作。採 `main.go`(root,組合根)+ `cmd/backup/`(命令層)+ `svc/backup/`(服務層,封裝 macOS `defaults`/`plutil` 互動)三層,不使用 cobra;由 `build.sh` 建置到 `~/.local/bin/macbackup`(git-ignored,不 commit binary)。
- **macOS 稽核與硬體偵測分流**：`bin/mac/` 為 macOS 專屬 (`mac_cleanup.sh`、`*_audit-mac.sh`)；`bin/system/` 為跨平台硬體偵測 (`*_info`、`system_info`)。`bin/system/README.md` 目前標題錯置需修正。
- **原則上不引入 Go/Cobra 框架**：本 repo 以純 shell + python 工具集為主，不混用 binary CLI。唯一例外為 repo root 的 macbackup Go module(macOS 設定 backup/import 工具)：因需 gosdk config 慣例路徑 (`~/.config/env_setup/data/`) 與逐一 diff/確認的互動邏輯,以 Go 實作。採 `main.go`(root,組合根)+ `cmd/backup/`(命令層)+ `svc/backup/`(服務層,封裝 macOS `defaults`/`plutil` 互動)三層,不使用 cobra;由 `build.sh` 建置到 `~/.local/bin/macbackup`(git-ignored,不 commit binary)。

## 模組對應 (Module Mapping)

| 業務領域 (Domain)                                 | 套件/模組 (Package/Module)                                                                                                | 進入點 (Entry Point)                                                             |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| 機器初始化與開發工具安裝 (Bootstrap & Tooling)    | `scripts/`, `bin/bash/settings.sh`                                                                                        | `./scripts/mac.sh`, `./scripts/ubuntu.sh`, `./scripts/go.sh`                     |
| 使用者與 IDE 設定軟連結 (User Config & IDE Link)  | `run.sh`, `bin/bash/`, `bin/vscode/`                                                                                      | `./run.sh` (含 `link_ide_config()` 函式)                                         |
| 硬體與系統狀態偵測 (Hardware & System Probe)      | `bin/system/`                                                                                                             | `./bin/system/system_info`, `./bin/system/checkdisk`, `./bin/system/system_dump` |
| macOS 系統稽核與清理 (macOS Audit & Cleanup)      | `bin/mac/`                                                                                                                | `./bin/mac/mac_cleanup.sh`, `./bin/mac/disk_analysis-mac.sh`                     |
| 網路拓撲與設備掃描 (Network Topology & Scan)      | `bin/scan_private_network`, `bin/scan_target_network`, `bin/system/network_topology_scan.sh`                              | 對應入口直接執行 (規劃整合至 `bin/network/scan_network.sh`)                      |
| macOS 系統稽核與清理 (macOS Audit & Cleanup)      | `bin/mac/`                                                                                                                | `./bin/mac/mac_cleanup.sh`, `./bin/mac/disk_analysis-mac.sh`                     |
| 網路拓撲與設備掃描 (Network Topology & Scan)      | `bin/network/scan_network.sh` (--mode=private\|target\|topology\|topology-no-scan), `bin/system/network_topology_scan.sh` | `./bin/network/scan_network.sh --mode=...`                                       |
| 開發者輔助工具 (Developer Helpers)                | `bin/` 根目錄 + `bin/bash/.bash_aliases`                                                                                  | 任意 `bin/<tool>` (因 `~/bin` 已 symlink)                                        |
| 觀測排程與稽核報告 (Observability Cron & Reports) | `ecosystem.config.js` + `bin/mac/*_audit-mac.sh`                                                                          | `pm2 start ecosystem.config.js`                                                  |

## 開發指南 (Development Guide)

### 前置需求 (Prerequisites)

- macOS 或 Ubuntu Linux
- Bash/Zsh 終端機
- 已安裝 `git`、`wget`、`curl` (macOS 內建, Ubuntu 由 `scripts/ubuntu.sh` 安裝)
- `traceroute` + `nmap` (僅執行 network scanner 需)

### 安裝 (Installation)

```bash
# macOS
./scripts/mac.sh

# Ubuntu
./scripts/ubuntu.sh

# 建立 dotfile 與 IDE 軟連結
./run.sh
```

### 建置 (Build)

無編譯步驟；新工具直接以可執行檔形式加入 `bin/<area>/<tool>` 並 `chmod +x`。

### 測試 (Test)

- `./run.sh` 驗證 symlink 全部建立
- `./bin/system/system_info` 驗證 10 個 sub-tool (需先修 `BASE_DIR` bug)
- `./bin/mac/disk_analysis-mac.sh` 驗證 audit 報告輸出
- `shellcheck bin/<area>/*.sh` (若已安裝)
- `git grep -n 'smain\|project_setup'` 確認無殘留敘述
- `git grep -n 'smain\|project_setup'` 確認無殘留敘述

### 部署 (Deploy)

未偵測到部署設定 (No deployment config detected)；本 repo 為本機使用工具，無對外服務。

## 慣例 (Conventions)

- Shell 腳本命名 (Naming)：
    - 跨平台腳本 `bin/system/<component>_<type>` (例：`os_info`、`system_dump`)
    - macOS 腳本 `bin/mac/<mac_action>.sh` 或 `bin/mac/<mac_action>` (規劃統一加 `mac_` 前綴與 `.sh` 後綴)
    - helper 腳本 `bin/<area>/_lib_<purpose>.sh` (例：規劃中之 `bin/mac/_lib_audit.sh`)
- 環境變數入口 (Settings)：
    - 所有腳本 `source "$(dirname "$0")/settings.sh"` 取得共用變數
    - 不得在 `bin/bash/settings.sh` 內 commit 明文 `passwd` / `email` / `token`，一律改讀 `~/.config/env_setup/settings.private.sh`
- 工具加入流程 (Scalability)：
    1. 決定 area: `bash` / `mac` / `system` / `vscode` / `network`
    2. 在 `bin/<area>/<tool>` 撰寫；需要共用 helper 時 `source bin/<area>/_lib_*.sh`
    3. 若需 root 入口，在 `bin/<tool>` 加 symlink `bin/<tool> -> <area>/<tool>`
    4. 將工具加入 `docs/bin_index.md`
    5. 若需排程，在 `ecosystem.config.js` 用 `./bin/<area>/<tool>` 全路徑註冊
- 共用 helper 慣例 (Shared Helper):
    - 跨腳本共用函式 / 樣板 / 常數放至 `bin/<area>/_lib_<purpose>.sh` (底線前綴標明「非直接執行, 僅供 source」)
    - 使用方式: `source "$(dirname "$0")/_lib_<purpose>.sh"`
    - 範例: `bin/mac/_lib_audit.sh` 提供 `term_log` / `md_log` / `log` / `header` / `audit_init` 給所有 `bin/mac/*_audit-mac.sh` 使用
- 環境變數入口 (Settings):
    - 所有腳本 `source "$(dirname "$0")/../bash/settings.sh"` 取得 `REPO_DIR`, `REPO_SCRIPTS`, `OS`, `ARCH`, `KERNEL_NAME`
    - 不得在 `bin/bash/settings.sh` 內 commit 明文 `passwd` / `email` / `token` / API key; 私密值一律讀 `~/.config/env_setup/settings.private.sh` 或 `~/.bash_local`
- 個人 alias (Personal Alias):
    - 公開 / 共用 alias 寫 `bin/bash/.bash_aliases` (git tracked)
    - 含私密 token 的 alias (`claudew-s` / `claudew-b` / `claudew2` 等) 寫 `~/.bash_local` (git-ignored), 範本見 `docs/notes/bash-local-aliases.md`；基礎 `claudew` / `claudem` 已提升為 `bin/claudew` / `bin/claudem` 實體 script file (取代 alias 以避免 alias 對 `set -e` 與 stdin 行為的限制)
- 共用 helper 慣例 (Shared Helper):
    - 跨腳本共用函式 / 樣板 / 常數放至 `bin/<area>/_lib_<purpose>.sh` (底線前綴標明「非直接執行, 僅供 source」)
    - 使用方式: `source "$(dirname "$0")/_lib_<purpose>.sh"`
    - 範例: `bin/mac/_lib_audit.sh` 提供 `term_log` / `md_log` / `log` / `header` / `audit_init` 給所有 `bin/mac/*_audit-mac.sh` 使用
- 環境變數入口 (Settings):
    - 所有腳本 `source "$(dirname "$0")/../bash/settings.sh"` 取得 `REPO_DIR`, `REPO_SCRIPTS`, `OS`, `ARCH`, `KERNEL_NAME`
    - 不得在 `bin/bash/settings.sh` 內 commit 明文 `passwd` / `email` / `token` / API key; 私密值一律讀 `~/.config/env_setup/settings.private.sh` 或 `~/.bash_local`
- 個人 alias (Personal Alias):
    - 公開 / 共用與預配置之 alias 寫 `bin/bash/.bash_aliases` (git tracked)
    - 私密 token 與敏感值變數寫 `~/.bash_local` (git-ignored)，不放 alias 在此，範本見 `docs/notes/bash-local-aliases.md`
- 錯誤處理 (Error Handling)：
    - 關鍵腳本使用 `set -euo pipefail`
    - 缺相依工具 (`traceroute` / `nmap`) 時直接報錯退出，避免 silently 產出空報告
- 記錄日誌 (Logging)：
    - pm2 任務輸出由 pm2 收集；audit 報告以 `term_log` / `md_log` 寫入 `$AUDIT_REPORT_DIR`
- 設定儲存 (Configuration)：
    - dotfiles 由 `scripts/bash_env_setup.sh` 軟連結到 `~/`
    - 全機 `/etc/*` 設定由 `run.sh` 軟連結到 `./tmp/`
    - 個人敏感設定一律存於 `~/.config/env_setup/settings.private.sh` (git-ignored)
