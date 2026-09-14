# env_setup — 技術脈絡 (Technical Context)

## 專案結構 (Project Structure)

```text
.
├── LICENSE
├── README.md                      # 業務定義 + domain flow
├── README.business.md             # 業務價值萃取
├── README.todo                    # 待辦 + 已完成 Archive
├── CLAUDE.md
├── AGENTS.md -> CLAUDE.md
├── GEMINI.md -> CLAUDE.md
├── setup.sh                       # 互動式初始化 wizard (personal info / bash env / tools)
├── run.sh                         # 唯一 symlink 入口 + IDE profile 套用
├── ecosystem.config.js            # pm2 cron 任務
├── package.json                   # 唯一任務清單 (lint / test / clean / ci)
├── .claudeignore
├── .geminiignore -> .gitignore
├── .gemini -> .claude
├── .gitmodules                    # 9 個 vim 插件 + libgit2
├── .claude/ / .vscode/            # repo 自身 agent / VSCode 設定
├── bin/
│   ├── bash/                      # dotfiles + settings.sh + helper
│   │   ├── settings.sh            # 共用環境變數 (USER_BIN, REPO_DIR...)
│   │   ├── .bashrc / .bash_aliases / .bash_function / .bash_logout
│   │   ├── .gitconfig / .gitmessage / .gitignore
│   │   ├── .vimrc / .vim/         # 內含 9 個 plugin submodules
│   │   ├── .screenrc / .toprc / .npmrc
│   │   ├── backup.ignore
│   │   ├── cmd_usage.md           # 個人 cheat notes
│   │   ├── README.md
│   │   └── shell_script_sample.sh
│   ├── mac/                       # macOS 專用工具
│   │   ├── mac_static_ip.sh       # 固定 IPv4 / 顯示狀態 / 還原 DHCP
│   │   ├── _lib_audit.sh          # audit 腳本共用 helper (僅供 source)
│   │   ├── launch_audit-mac.sh / login_audit-mac.sh
│   │   ├── network_security_audit-mac.sh
│   │   ├── mac_keyboard_shortcuts_dump.sh / mac_keyboard_shortcuts_restore.sh
│   │   ├── mac_extension_list.sh
│   │   ├── lib.py / ls_sys_path.py / sys_path
│   │   └── keyboard_shortcuts/    # plist 樣板
│   ├── vscode/                    # IDE 設定 + manifests / restore
│   │   ├── settings.json / keybindings.json
│   │   ├── snippets/
│   │   ├── agy-ide_extension_list.txt / vscode_extension_list.txt
│   │   └── README.md
│   ├── go -> ~/.local/go<version>/bin/go  # scripts/go.sh 建立的鎖版 symlink (machine-local, bin/.gitignore 排除)
│   ├── config/ / share/           # machine-local 執行期資料 (bin/.gitignore 排除)
│   ├── 根目錄 helpers             # 詳見 docs/bin_index.md
│   │   ├── json / git_signing / find_symbolic_link
│   │   ├── iconv_big5_utf8 / file_encoding / reverse_ln
│   │   ├── generate_https_cert / generator_pem.sh
│   │   ├── backup / backupSync
│   │   ├── ssoLogin.sh / ssoLogin_faas.sh
│   │   ├── claudew / claudem / devcontainer
│   │   ├── ssh_config / sshd_config / ssh_keygen / ssh_key_compare
│   │   ├── ssh.md
│   │   ├── strip-docker-image-README.md
│   │   └── settings.sh -> bash/settings.sh
├── scripts/                       # OS / tool installer 與純 Shell 領域工具
│   ├── check_prereq.sh            # 前置條件檢查 (bash env、Node / pnpm CLI、套件庫)
│   ├── _lib_bash_plugin.sh        # .bash_plugin idempotent 區塊替換共用函式
│   ├── mac.sh / ubuntu.sh         # macOS / Ubuntu 全套 bootstrap 編排腳本
│   ├── mac_basic.sh / uv.sh       # macOS 基礎工具 (curl/wget/jq) 與 Python uv
│   ├── ubuntu_apt.sh / ubuntu_locale.sh / ubuntu_timezone.sh / ubuntu_user.sh
│   ├── bash_env_setup.sh          # dotfile 軟連結入口
│   ├── bash.sh / settings.sh      # scripts 內部 settings
│   ├── brew.sh                    # Homebrew 5.0.3 安裝
│   ├── go.sh                      # Go 1.26.6 + golangci-lint
│   ├── nodejs.sh / nodejs_nvm.sh / pnpm.sh / nodejs.md
│   ├── openssl_setup.sh / openssl_mac_setup.sh / openssl.cnf / openssl.md
│   ├── ctags_setup.sh
│   ├── git-secret.sh / git.sh / git.md
│   ├── vim.sh / vim.md
│   ├── webmin.sh
│   ├── test_bash_plugin.sh        # .bash_plugin 區塊替換單元測試
│   ├── test_docker_install.sh     # Docker 容器隔離安裝與命令驗證測試
│   ├── Brewfile
│   ├── backup/                    # defaults 偏好設定備份、還原與檢視
│   │   ├── backup.sh / list.sh / import.sh / init.sh
│   ├── cleanup/                   # 系統暫存、快取、日誌與容器清理
│   │   ├── all.sh / _lib_cleanup.sh
│   │   ├── system_log.sh / system_tmp.sh / cache_user.sh
│   │   ├── docker.sh / brew.sh / node.sh / python.sh / go.sh
│   │   └── ai.sh / browser.sh / app.sh
│   ├── disk/                      # mount_disk.sh / mount_disk_by_fstab.sh
│   ├── dump/                      # 開發環境清單匯出 (Homebrew, VS Code, Antigravity)
│   │   ├── mac.sh / vscode.sh / antigravity.sh
│   ├── install/                   # IDE 擴充套件安裝與同步
│   │   ├── vscode.sh / antigravity.sh
│   ├── io/                        # 裝置層 I/O 探測與基準評測
│   │   ├── probe.sh / bench.sh
│   ├── network/                   # 私有路由與目標網段掃描
│   │   ├── private.sh / target.sh
│   ├── system/                    # 硬體與系統各項狀態探測
│   │   ├── show.sh / disk_verify.sh
│   │   ├── os.sh / cpu.sh / memory.sh / gpu.sh / disk.sh
│   │   └── usb.sh / display.sh / network.sh / input.sh / audio.sh
│   ├── uninstall/                 # Codex 移除
│   │   └── codex.sh
│   └── README.md
├── pkg/                           # 第三方 source + 樣板
│   ├── libgit2.sh                 # libgit2 helper (submodule pkg/libgit2 需自行 init)
│   ├── mac/
│   │   ├── setup.sh / globalp.plist / README.md
│   │   ├── LaunchAgents/          # plist 樣板
│   │   └── applescript/           # toggleFn.scpt
│   ├── sysctl/pf.conf             # PF firewall 樣板 (其餘樣板見 docs/templates/sysctl/)
│   └── README.md
├── docs/
│   ├── bin_index.md               # bin/ 完整索引 (單一擁有者)
│   ├── terminology.md             # 術語表
│   ├── memory/                    # 歷史操作與決策 retrospective
│   ├── specs/                     # 既有設計與規格 (YYYY-MM-DD-<topic>.md)
│   ├── notes/                     # 個人學習筆記 (ubuntu / shell / bash-local)
│   ├── templates/sysctl/          # sysctl.conf / security / pam.d 樣板
│   └── superpowers/               # skill 產出之 plans / specs
├── troubleshooting/               # 故障排除腳本
│   ├── exfat.sh / Transcend.sh
│   ├── usb_disk.md / ubuntu_build_error.md
│   └── image/
└── tmp/                           # run.sh 軟連結目標 (唯一)
```

## 技術棧 (Tech Stack)

- Language: Bash/Shell (主要)、Python (輔助)、AppleScript
- Task Runner: `package.json` (npm scripts 管理 lint / test / clean / ci 與領域任務進入點)
- Scheduler: `pm2` (`ecosystem.config.js` 集中管理定時稽核與系統探測)
- Key dependencies:
    - `homebrew 5.0.3` (`scripts/brew.sh`)
    - `go 1.26.6` (`scripts/go.sh`)
    - `node v24.11.1` via nvm (`scripts/nodejs_nvm.sh`) + `pnpm 12.4.1` (`scripts/pnpm.sh`)
    - `traceroute` / `nmap` (網路掃描前置)
    - `system_profiler` (macOS 硬體偵測)
    - `lshw` / `lsblk` (Linux 硬體偵測)
    - `pm2` (`go install github.com/bizshuk/pm2@master`)
    - `cc-plugin` skills (`go install github.com/bizshuk/skills@master`)

## 關鍵決策 (Key Decisions)

- **`~/.bash_plugin` 寫入全面落實 idempotent 區塊替換**：所有安裝腳本 (`brew.sh`, `go.sh`, `nodejs_nvm.sh`, `pnpm.sh`, `openssl_mac_setup.sh`, `mac.sh`, `ctags_setup.sh`) 統一透過 `scripts/_lib_bash_plugin.sh` 的 `update_bash_plugin_block` 管理。設定以 `# >>> env_setup <component> >>>` / `# <<< env_setup <component> <<<` marker 包夾，重跑時先刪除舊區塊與歷史未標記行再以原子方式覆寫，避免重複追加造成 PATH 膨脹與版本衝突。
- **`bin/bash/settings.sh` 為唯一環境變數入口**：所有腳本 `source settings.sh` 取得 `USER_BIN`、`REPO_DIR`、`REPO_SCRIPTS`、`OS`、`ARCH`、`KERNEL_NAME` 等；個人敏感值 (`passwd`/`email`/`token`) 改由 `~/.config/env_setup/settings.private.sh` 提供 (git-ignored)。
- **`~/bin` symlink 到 `bin/`**：在 `settings.sh` 內 `[ ! -e "$USER_BIN" ] && ln -s "$USER_PROJECT/env_setup/bin" "$USER_BIN"`，新工具直接落入 `bin/<area>/<tool>` 即可被 `PATH` 找到。
- **IDE profile 由 `run.sh` 依 OS 雙綁**：同時把 `bin/vscode/{settings,keybindings,snippets}` 連結到 VSCode (`Code/User`) 與 Antigravity IDE 的 `User/` 目錄。
- **`package.json` 是唯一任務清單**：`npm run ci` = `lint` → `test`，統一透過 npm scripts 管理所有安裝、同步、探測與生命週期任務；`lint` 透過 `bash -n` 靜態語法檢查驗證 `scripts/` 與 `bin/` 所有腳本；`clean` 僅清除日誌與暫存廢棄檔，安全保留 `tmp/` 目錄與符號連結。
- **pm2 為唯一排程器**：`ecosystem.config.js` 集中所有 cron 任務，namespace = `Local`；所有任務統一以 `./scripts/<domain>/<tool>.sh` 或 `./bin/<area>/<tool>` 全路徑註冊，包含磁碟清理 preview、macOS 安全稽核、硬體與 I/O 探測、備份狀態檢測以及網路拓撲探測等全套非安裝類檢查任務。
- **macOS 稽核與清理分流**：`scripts/cleanup/` 擁有 cleanup catalog、preview 與逐項 confirmation；`bin/mac/*_audit-mac.sh` 保留 audit reports；跨平台硬體偵測由 `scripts/system/` 擁有。
- **純 Shell 領域腳本架構**：廢除 Go CLI，所有領域功能（backup、cleanup、dump、install、io、network、system、uninstall）全面下沉為 `scripts/<domain>/` 下的純 Shell 獨立腳本，並透過 `package.json` npm scripts 提供統一執行介面。
- **backup metadata 是 snapshot time owner**：`scripts/backup/list.sh` 的 latest backup date 讀取 `backup.meta.json.timestamp`；legacy backup 缺少 metadata 時才 fallback 至最新 `.plist` modification time，沒有任何 backup 則顯示 `-`。
- **manifest sync 是純 Shell 服務**：`scripts/dump/` (mac, vscode, antigravity) 擁有 manifest export；`scripts/install/` 以 tracked manifest 安裝 extensions，並在移除 unlisted extensions 前要求 `y/Y` confirmation。IDE dump output 在完整取得後排序、去重並以原子方式覆寫。
- **system probes 與 disk verification 是純 Shell 服務**：`scripts/system/` 依 platform 執行 native commands 並格式化輸出；`scripts/system/show.sh` 聚合全部 probes，`scripts/system/<information>.sh` 執行單一 probe；`scripts/system/disk_verify.sh` 在 macOS 以 `diskutil` + F3 驗證 removable media。
- **I/O probe 是裝置層、跨平台的純 Shell 服務**：`scripts/io/probe.sh` 以 `lsblk -J` + sysfs（Linux）或 `diskutil info`（macOS）列出每顆實體磁碟的規格；`scripts/io/bench.sh` 進行基準測試。
- **network scans 是純 Shell 服務**：`scripts/network/` 執行 `traceroute`、`nmap` 與 bounded ping fallback，並解析 private hops、live hosts 與 topology。
- **cleanup apply 遵循 safe-by-default preview**：`scripts/cleanup/` 預設執行 preview 解析 exact targets 與 size；只有 `--apply` 且逐項確認後才套用該 snapshot 執行刪除。
- **Codex uninstall 遵循 safe-by-default preview**：`scripts/uninstall/codex.sh` 預設只列出 targets；只有加上 `--apply` 並逐項確認後才執行移除。

## 模組對應 (Module Mapping)

| 業務領域 (Domain)                                 | 套件/模組 (Package/Module)                                                                                                | 進入點 (Entry Point)                                                             |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| 機器初始化與開發工具安裝 (Machine Bootstrap & Tooling Install) | `scripts/`, `bin/bash/settings.sh`                                                                                        | `./scripts/mac.sh`, `./scripts/ubuntu.sh`, `./scripts/go.sh`                     |
| 使用者與 IDE 設定軟連結 (User Config & IDE Symlink Bootstrap) | `run.sh`, `bin/bash/`, `bin/vscode/`                                                                                      | `./run.sh` (含 `link_ide_config()` 函式)                                         |
| 硬體與系統狀態偵測 (Hardware & System Probe)      | `scripts/system/`                                                                                                         | `npm run run:system:show`, `npm run run:system:<information>`, `npm run run:system:disk-verify`；純腳本：`scripts/system/*.sh` |
| 開發環境清單同步 (Development Manifest Sync)      | `scripts/dump/`, `scripts/Brewfile`, `bin/vscode/*_extension_list.txt`                                                     | `npm run run:dump:mac`, `npm run run:dump:vscode`, `npm run run:dump:antigravity`；純腳本：`scripts/dump/*.sh` |
| IDE 擴充套件同步 (IDE Extension Sync)             | `scripts/install/`, `bin/vscode/*_extension_list.txt`                                                                     | `npm run run:install:vscode`, `npm run run:install:antigravity`；純腳本：`scripts/install/*.sh` |
| macOS 設定備份 (macOS Defaults Backup)            | `scripts/backup/`                                                                                                         | `npm run run:backup`, `npm run run:backup:list`, `npm run run:backup:import`, `npm run run:backup:init`；純腳本：`scripts/backup/*.sh` |
| macOS Codex 移除 (macOS Codex Uninstall)          | `scripts/uninstall/`                                                                                                      | `npm run run:uninstall:codex`；純腳本：`scripts/uninstall/codex.sh`               |
| macOS 系統稽核與清理 (macOS Audit & Cleanup)      | `scripts/cleanup/`, `bin/mac/*_audit-mac.sh`                                                                              | `npm run run:cleanup`, `npm run run:cleanup:<target>`；純腳本：`scripts/cleanup/*.sh` |
| 網路拓撲與設備掃描 (Network Topology & Device Scan) | `scripts/network/`                                                                                                        | `npm run run:network:private`, `npm run run:network:target`；純腳本：`scripts/network/*.sh` |
| 裝置層 I/O 探測 (Device I/O Probe)                | `scripts/io/`                                                                                                             | `npm run run:io:probe`, `npm run run:io:bench`；純腳本：`scripts/io/*.sh`         |
| 開發者輔助工具 (Developer Helpers)                | `bin/` 根目錄 + `bin/bash/.bash_aliases`                                                                                  | 任意 `bin/<tool>` (因 `~/bin` 已 symlink)                                        |
| 觀測排程與稽核報告 (Observability Cron & Audit Reports) | `ecosystem.config.js` + `bin/mac/*_audit-mac.sh`                                                                          | `pm2 start ecosystem.config.js`                                                  |

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

本 repo 為純 Shell 腳本工具箱，無需二進位編譯步驟。工具直接編寫於 `scripts/` 或 `bin/<area>/<tool>` 並賦予執行權限 (`chmod +x`)；專案與領域任務由 `package.json` 的 npm scripts 統一管理。

### 測試 (Test)

- `./run.sh` 驗證 symlink 全部建立
- `npm run lint` 驗證 `scripts/` 與 `bin/` 所有 `.sh` 腳本之語法正確性 (`bash -n`)
- `npm test` 執行 `scripts/test_bash_plugin.sh` 驗證區塊替換 idempotent 單元測試
- `npm run test:docker` 於隔離的 Ubuntu 容器中驗證完整 toolchain 安裝與命令驗證（需本機 Docker 或 Colima 運作中）
- `./bin/mac/launch_audit-mac.sh` 驗證 audit 報告輸出
- `shellcheck bin/<area>/*.sh` (若已安裝)
- `git grep -n 'smain\|project_setup'` 確認無殘留敘述

### CI/CD

本地與整合驗證透過 `npm run ci` (`npm run lint && npm run test`) 執行，確保所有 Shell 腳本無語法錯誤且 plugin 區塊管理具備冪等性；已移除 GitHub Actions 工作流程，所有驗證可在本機或容器內自主完成。

### 部署 (Deploy)

未偵測到部署設定 (No deployment config detected)；本 repo 為本機使用工具，無對外服務。

## 慣例 (Conventions)

- Shell 腳本命名 (Naming)：
    - 系統資訊探測統一置於 `scripts/system/<information>.sh` 與 `scripts/system/show.sh`
    - 網路掃描統一置於 `scripts/network/private.sh` 與 `scripts/network/target.sh`
    - macOS 腳本 `bin/mac/<mac_action>.sh` 或 `bin/mac/<mac_action>` (規劃統一加 `mac_` 前綴與 `.sh` 後綴)
    - helper 腳本 `bin/<area>/_lib_<purpose>.sh` 或 `scripts/<domain>/_lib_*.sh` (底線前綴標明「非直接執行, 僅供 source」)
- 工具加入流程 (Scalability)：
    1. 決定 area: `scripts/<domain>` (領域腳本) 或 `bin/<area>/<tool>` (輔助工具)
    2. 在對應目錄撰寫腳本；需要共用 helper 時 `source _lib_*.sh`
    3. 若需 root 入口，在 `bin/<tool>` 加 symlink `bin/<tool> -> <area>/<tool>`
    4. 將工具加入 `docs/bin_index.md`
    5. 若需排程，在 `ecosystem.config.js` 註冊全路徑：`./scripts/<domain>/<tool>.sh` 或 `./bin/<area>/<tool>`
    6. 若需 npm 統一入口，在 `package.json` 的 `scripts` 註冊 `run:<domain>:<action>`
- 共用 helper 慣例 (Shared Helper):
    - 使用方式: `source "$(dirname "$0")/_lib_<purpose>.sh"`
    - 範例: `bin/mac/_lib_audit.sh` 提供 `term_log` / `md_log` / `log` / `header` / `audit_init` 給所有 `bin/mac/*_audit-mac.sh` 使用
- 環境變數入口 (Settings):
    - 所有腳本 `source "$(dirname "$0")/../bash/settings.sh"` 取得 `REPO_DIR`, `REPO_SCRIPTS`, `OS`, `ARCH`, `KERNEL_NAME`
    - 不得在 `bin/bash/settings.sh` 內 commit 明文 `passwd` / `email` / `token` / API key; 私密值一律讀 `~/.config/env_setup/settings.private.sh` 或 `~/.bash_local`
- 個人 alias (Personal Alias):
    - `env_setup 自有 alias` 一律寫 `bin/bash/.bash_aliases` (git tracked)；alias 只引用變數名，不內嵌 token 值
    - `LLM CLI alias` (`claude*` / `codex*` / `claudew-s` / `claudew-b` / `claudew2`) 由 `~/projects/ai/cc-plugin/scripts/aliases.sh` 單一擁有，`.bash_aliases` 只負責 source 它；不得在本 repo 內重複定義
    - `~/.bash_local` (git-ignored) `只放變數`，不放 alias；由 `.bash_aliases` 於 alias 定義前 source 一次，範本見 `docs/notes/bash-local-aliases.md`
    - 基礎 `claudew` / `claudem` 已提升為 `bin/claudew` / `bin/claudem` 實體 script file (取代 alias 以避免 alias 對 `set -e` 與 stdin 行為的限制)
- 錯誤處理 (Error Handling)：
    - 關鍵腳本使用 `set -euo pipefail`
    - 缺相依工具 (`traceroute` / `nmap`) 時直接報錯退出，避免 silently 產出空報告
- 記錄日誌 (Logging)：
    - pm2 任務輸出由 pm2 收集；audit 報告以 `term_log` / `md_log` 寫入 `$AUDIT_REPORT_DIR`
- 設定儲存 (Configuration)：
    - dotfiles 由 `scripts/bash_env_setup.sh` 軟連結到 `~/`
    - 全機 `/etc/*` 設定由 `run.sh` 軟連結到 `./tmp/`
    - 個人敏感設定一律存於 `~/.config/env_setup/settings.private.sh` (git-ignored)
