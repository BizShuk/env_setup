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
├── go.mod / go.sum                # env_setup Go module (Cobra + gosdk)
├── main.go                        # env_setup composition root
├── build.sh                       # go build -> ~/.local/bin/env_setup
├── cmd/
│   ├── root.go                    # Cobra root + gosdk metric hook
│   ├── command_file_test.go       # one command one named file architecture contract
│   ├── cleanup/
│   │   └── cleanup.go             # cleanup list / --apply confirmation
│   ├── dump/
│   │   ├── dump.go                # dump parent command
│   │   ├── mac.go                 # Homebrew / cask / tap / MAS manifest
│   │   ├── vscode.go              # VS Code extensions manifest
│   │   └── antigravity.go         # Antigravity extensions manifest
│   ├── backup/
│   │   ├── backup.go              # backup parent command
│   │   ├── import.go              # backup import command
│   │   ├── init.go                # backup init command
│   │   └── list.go                # backup list command
│   ├── network/
│   │   ├── network.go             # network parent command
│   │   ├── private.go             # private route topology command
│   │   └── target.go              # target CIDR discovery command
│   └── system/
│       ├── system.go              # system parent command
│       ├── show.go                # aggregate show command
│       ├── os.go / osShow.go
│       ├── cpu.go / cpuShow.go
│       ├── memory.go / memoryShow.go
│       ├── gpu.go / gpuShow.go
│       ├── disk.go / diskShow.go
│       ├── usb.go / usbShow.go
│       ├── display.go / displayShow.go
│       ├── network.go / networkShow.go
│       ├── input.go / inputShow.go
│       └── audio.go / audioShow.go
├── model/cleanup/                 # cleanup preview 純資料模型
├── svc/cleanup/                   # discovery、size、exact-target apply
├── svc/backup/                    # backup service (與 macOS defaults/plutil 互動 + 邏輯)
├── svc/dump/                      # manifest commands、normalization、atomic write
├── svc/network/                   # traceroute/nmap execution、parsing、topology rendering
├── svc/system/                    # system catalog、platform command execution/parsing
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
│   │   ├── mac_static_ip.sh       # 固定 IPv4 / 顯示狀態 / 還原 DHCP
│   │   ├── disk_analysis-mac.sh / launch_audit-mac.sh
│   │   ├── login_audit-mac.sh / network_security_audit-mac.sh
│   │   ├── mac_keyboard_shortcuts_dump.sh / mac_keyboard_shortcuts_restore.sh
│   │   ├── mac_keyboard_shortcuts_dump.sh / mac_keyboard_shortcuts_restore.sh
│   │   ├── mac_extension_list
│   │   ├── lib.py / ls_sys_path.py
│   │   └── keyboard_shortcuts/    # plist 樣板
│   ├── disk/                      # large-file scan
│   │   └── list_big_files.sh
│   ├── codex/                     # Codex lifecycle utilities
│   │   └── uninstall.sh
│   ├── vscode/                    # IDE 設定 + manifests / restore
│   │   ├── settings.json / keybindings.json
│   │   ├── snippets/
│   │   ├── agy-ide_extension_install
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

- Language: Bash/Shell (主要)、Go 1.26 (env_setup CLI)、Python (輔助)、AppleScript
- Framework: `spf13/cobra` (CLI) + `bizshuk/gosdk` (config、logging、metrics)
- Build tool: `go build` (root CLI)；shell scripts 直接執行
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
- **macOS 稽核與 cleanup 分流**：`env_setup cleanup` 擁有 cleanup catalog、preview 與逐項 confirmation；`bin/mac/*_audit-mac.sh` 保留 audit reports；跨平台硬體偵測由 `svc/system` 擁有。
- **Cobra root 是唯一 Go CLI 入口**：`main.go` 初始化 gosdk config，`cmd/root.go` 組合 `cleanup`、`backup`、`dump`、`system` 與 `network` subcommands；domain I/O 分別下沉至對應的 `svc/<domain>/`。
- **Cobra command 一個檔案一個 command**：檔名採 package-relative command path，不重複 package prefix。Package/root command 使用 `<package>.go`，direct child 使用 `<child>.go`，更深層 command 串接剩餘 path（例如 `cmd/backup/import.go`、`cmd/system/osShow.go`）。Host app 使用 constructor injection 建立 fresh command tree，避免 package-level flag state 在 tests 間殘留。
- **backup metadata 是 snapshot time owner**：`backup list` 的 latest backup date 讀取 `backup.meta.json.timestamp`；legacy backup 缺少 metadata 時才 fallback 至最新 `.plist` modification time，沒有任何 backup 則顯示 `-`。
- **manifest dump 是 Go-native service**：`env_setup dump mac|vscode|antigravity` 分別擁有 Homebrew、VS Code 與 Antigravity manifest export；IDE output 在完整取得後排序、去重並 atomic replace，舊 shell adapters 與 root symlinks不再是 runtime boundary。
- **system probes 與 disk verification 是 Go-native services**：`svc/system` 透過 injected `Runner` 執行 platform commands，並由 information-specific Go files 解析輸出；不依賴 repo path 或 shell adapters。`system show` 聚合全部 probes，`system <information> show` 執行單一 probe；`system disk verify <volume-path>` 在 macOS 以 `diskutil` + F3 驗證 removable media。
- **network scans 是 Go-native services**：`svc/network` 透過 injected `Runner` 執行 `traceroute`、`nmap` 與 bounded ping fallback，並由 Go parser 解析 private hops、live hosts、services 與 topology；`bin/network/` 不再是 runtime boundary。
- **cleanup apply 使用 immutable snapshot**：`svc/cleanup` 在 preview 時解析 exact targets 與 size；只有 `--apply` 且逐項確認後才套用該 snapshot，不在 apply 時重新擴大 glob scope。

## 模組對應 (Module Mapping)

| 業務領域 (Domain)                                 | 套件/模組 (Package/Module)                                                                                                | 進入點 (Entry Point)                                                             |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| 機器初始化與開發工具安裝 (Bootstrap & Tooling)    | `scripts/`, `bin/bash/settings.sh`                                                                                        | `./scripts/mac.sh`, `./scripts/ubuntu.sh`, `./scripts/go.sh`                     |
| 使用者與 IDE 設定軟連結 (User Config & IDE Link)  | `run.sh`, `bin/bash/`, `bin/vscode/`                                                                                      | `./run.sh` (含 `link_ide_config()` 函式)                                         |
| 硬體與系統狀態偵測 (Hardware & System Probe)      | `cmd/system/`, `svc/system/`                                                                                               | `env_setup system show`, `env_setup system <information> show`, `env_setup system disk verify <volume-path>` |
| 開發環境清單匯出 (Development Manifest Dump)      | `cmd/dump/`, `svc/dump/`, `scripts/Brewfile`, `bin/vscode/*_extension_list.txt`                                            | `env_setup dump mac`, `env_setup dump vscode`, `env_setup dump antigravity`      |
| macOS 系統稽核與清理 (macOS Audit & Cleanup)      | `cmd/cleanup/`, `model/cleanup/`, `svc/cleanup/`, `bin/mac/*_audit-mac.sh`                                                | `env_setup cleanup`, `env_setup cleanup --apply`                                 |
| 網路與設備掃描 (Network & Device Scan)            | `cmd/network/`, `svc/network/`                                                                                            | `env_setup network private [target]`, `env_setup network target [cidr]`          |
| 開發者輔助工具 (Developer Helpers)                | `bin/` 根目錄 + `bin/bash/.bash_aliases`                                                                                  | 任意 `bin/<tool>` (因 `~/bin` 已 symlink)                                        |
| 觀測排程與稽核報告 (Observability Cron & Reports) | `ecosystem.config.js` + `bin/mac/*_audit-mac.sh`                                                                          | `pm2 start ecosystem.config.js`                                                  |

## 開發指南 (Development Guide)

### 前置需求 (Prerequisites)

- macOS 或 Ubuntu Linux
- Bash/Zsh 終端機
- 已安裝 `git`、`wget`、`curl` (macOS 內建, Ubuntu 由 `scripts/ubuntu.sh` 安裝)
- `traceroute` + `nmap` (僅執行 network scanner 需)
- `f3` (僅執行 macOS removable-media verification 需)

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

Root Go CLI 執行 `./build.sh` 安裝至 `~/.local/bin/env_setup`；shell 工具直接加入 `bin/<area>/<tool>` 並 `chmod +x`。

### 測試 (Test)

- `./run.sh` 驗證 symlink 全部建立
- `go test -count=1 ./...` 驗證 Cobra commands、system probes、network parsers、cleanup discovery 與 immutable apply
- `env_setup system show` 驗證 10 個 system information adapters
- `./bin/mac/disk_analysis-mac.sh` 驗證 audit 報告輸出
- `shellcheck bin/<area>/*.sh` (若已安裝)
- `git grep -n 'smain\|project_setup'` 確認無殘留敘述
- `git grep -n 'smain\|project_setup'` 確認無殘留敘述

### 部署 (Deploy)

未偵測到部署設定 (No deployment config detected)；本 repo 為本機使用工具，無對外服務。

## 慣例 (Conventions)

- Shell 腳本命名 (Naming)：
    - 跨平台 system information 以 `svc/system/<information>.go` 實作；不新增 shell adapter
    - network scans 以 `cmd/network/<command>.go` + `svc/network/` 實作；不新增 `bin/network/` adapter
    - macOS 腳本 `bin/mac/<mac_action>.sh` 或 `bin/mac/<mac_action>` (規劃統一加 `mac_` 前綴與 `.sh` 後綴)
    - helper 腳本 `bin/<area>/_lib_<purpose>.sh` (例：規劃中之 `bin/mac/_lib_audit.sh`)
- 環境變數入口 (Settings)：
    - 所有腳本 `source "$(dirname "$0")/settings.sh"` 取得共用變數
    - 不得在 `bin/bash/settings.sh` 內 commit 明文 `passwd` / `email` / `token`，一律改讀 `~/.config/env_setup/settings.private.sh`
- 工具加入流程 (Scalability)：
    1. 決定 area: `bash` / `mac` / `package` / `disk` / `codex` / `vscode` / `network`
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
