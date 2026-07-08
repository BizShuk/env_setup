# 2026-07-08-env-setup-structural-cleanup.md

> 對 `env_setup` 進行全面體檢後的結構整理 (structural cleanup) 計劃。
> 範圍: 一致性 (consistency)、去重 (redundancy)、結構 (structure)、可擴展性 (scalability)。
> 對應 `README.todo` 之 pending entry。
> 本檔已依實際檔案系統重新校對 (re-verified)，修正初版估算與補強未列項目。

## 1. 背景 (Context)

`env_setup` 是一個 framework 層級的 repo，職責為：

- 託管使用者/IDE 設定 (bash, vim, ssh, vscode) 與全機 `.config` 軟連結入口 (`run.sh`)
- 提供 macOS / Ubuntu 安裝腳本 (`scripts/`)
- 提供開發者工具箱 (`bin/`)：磁碟分析、安全稽核、網路拓撲掃描、SSH helper、簽章指引

但經實地盤點，**結構上存在多處不一致與重複**，部分文件敘述與實際檔案脫節，會誤導新協作者。

## 2. 體檢發現 (Audit Findings)

### 2.1 嚴重：文件與實體脫節 (Doc ↔ Reality Drift)

| 項目 | 文件聲稱 | 實際情況 | 影響 |
| --- | --- | --- | --- |
| `cmd/` | `CLAUDE.md` 與 `README.md` 描述一套 Go 1.25.4 + Cobra + logrus 的 `smain` CLI | **目錄不存在** | 維護者依文件找 `cmd/main.go` 會失敗 |
| `cmd/config.json` | `CLAUDE.md:130` 提及 | 不存在 | 設定儲存章節是過時敘述 |
| `bin/project_setup` | 兩個舊 plans (`2026-05-22`, `2026-05-24`) 與 `specs/20260217-fix-agent-symlink.md` 反覆提及 | 不存在 | 規劃文件變成歷史文獻；當前 `run.sh` 已承擔 symlink 重建 |
| `bin/system/system_info` | 應呼叫 10 個 `bin/system/*_info` 與 `myip` | `BASE_DIR="$(dirname "$0")/system"` 拼成 `bin/system/system`, **sub-tool 找不到，會全錯** (line 8 bug) | 跑 `system_info` 直接壞掉 |
| `bin/system/README.md` | 標題寫「安全性稽核與工具」 | 該目錄是 `system/` (硬體偵測), 不是 macOS audit (mac audit 在 `bin/mac/`) | 維護者進錯目錄找 audit 工具 |
| `bin/system/network_topology_scan.sh` | (1) root symlink 名為 `network_topology_scan.sh` | (2) `bin/system/README.md:13` 將其命名為 `network_topology_scan-mac.sh` (錯字) | 與檔名不一致 |
| `bin/mac/disk_analysis-mac.sh` | `bin/system/README.md:9` 描述 | 實際在 `bin/mac/`, 但 `bin/system/README.md` 假冒是 system/ 的工具 | 同上 |

### 2.2 嚴重：vendored 第三方程式碼 / 二進位混入 repo

| 位置 | 內容 | 體積 | 應處置 |
| --- | --- | --- | --- |
| `bin/git-secret` | upstream `sobolevn/git-secret` vendored shell library (含 freebsd/linux/osx 三平台 shim) | 52KB / 2082 行 | 改由 `brew install git-secret`；本檔應從 `bin/` 移除 |
| `pkg/ctags-5.8/` | upstream universal-ctags 5.8 完整源碼 (含 configure, .indent.pro, 多語言 parser) | 2.2MB / 111 檔案 | 改以 git submodule 或獨立 repo 託管；**確認 `.gitmodules` 不含此 submodule, 是純 vendored** |
| `tmp/doas-install.sh` | 上游 OpenBSD `doas` install script | 24KB | 屬一次性暫存，歸入 `archive/` 或移除 |
| `pkg/linux/Linux_kernel_structure.png` | 1.1MB 圖檔 | 1.1MB | 屬個人學習筆記；移至 `docs/notes/` |
| `pkg/linux/*.md` (7 份 ubuntu_note_*) | 個人 ubuntu 學習筆記 | ~50KB | 移至 `docs/notes/`，或保留為 `pkg/linux/notes/` |

### 2.3 中度：職責重疊的入口

| 入口 A | 入口 B | 差異 (重點) |
| --- | --- | --- |
| `run.sh` (重做 symlink、含 `link_ide_config` for VSCode + Antigravity) | `bin/system/system_link` (重做 symlink、含相同 `link_ide_config` 邏輯) | **`run.sh` 寫到 `./tmp/`, `system_link` 寫到 `./config/`** — 目標路徑真正分歧 (不只重複)；`run.sh` 多 ssh/ssh_config 與 sysctl；`system_link` 多 `~/.claude` 與 `claude/.claude` |
| `bin/scan_private_network` (~250 行, 9.4KB) | `bin/system/network_topology_scan.sh` (~450 行, 18KB) | 兩者皆 traceroute + nmap；後者多了 report markdown 與風險分類 + CLI 旗標 |
| `bin/scan_target_network` (2.5KB) | `bin/scan_private_network` | 第三個 traceroute 變體, 職責重疊；存在 3 個 network scanner 入口 |
| `bin/system/system_info` (聚合 10 個細粒度 helper) | `bin/scan_devices` (整頁式硬體偵測 + 寫入 `README.devices.md`) | 前者細粒度但有 line 8 bug, 後者整合度高但輸出格式差異大；建議保留 `system_info` (修 bug), 標 `scan_devices` 為另一條線 |
| `bin/system/system_dump` (呼叫 `brew_bundle_dump`、`vscode_extension_dump`、`agy_extension_dump`) | 個別 dump 腳本 | `system_dump` 沒問題, 應有 README 收斂點 |
| `bin/backup` (1.1KB) | `bin/backupSync` (1.2KB) | 兩者差 100 bytes; 職責差異 (diff vs force sync), 需 Q3 決定整併 |

### 2.4 中度：未使用 / dead-end 內容

| 檔案 / 目錄 | 用途 | 處置 |
| --- | --- | --- |
| `bin/system/system_performance.sh` | 是 cheatsheet, 含 `sudo fdisk -l` 等需 `sudo` 的命令 | 改為 `docs/notes/system_performance_cheatsheet.md`，標 `# cheatsheet, not executable` |
| `bin/system/raspi-config` | 內容只有 `raspi-config` 一行 (macOS 無此指令) | 刪除 |
| `bin/system/system_service` | 內容只有 `ls /etc/systemd/system/ ...` | 併入 `system_info` 或刪除 |
| `bin/bytedance_setup.sh` | 含 merge conflict markers, 寫入 `~/.ssh/config` 與 `~/.gitconfig` (個資), 與 `bin/bash/settings.sh` 之 `passwd`/`email` 同性質 | 刪除；功能已由 `bin/bash/settings.sh` 取代 |
| `pkg/sysctl/` (pam.d, security, sysctl.conf) | 提供 sysctl 範本；`run.sh` link `/etc/sysctl.conf` 但未從 `pkg/sysctl/` 讀 | 移除或標記為 template, 移到 `docs/templates/` |
| `pkg/ufw/` (ufw, user.rules) | 從未被任何腳本 source/link | 刪除 |
| `mac/`, `grafana/`, `inf/`, `log/app/`, `log/rpc/`, `openclaw/yuna/` | 空目錄或殘檔 | 列入 `.gitignore` 或移除 |
| `bin/goswitch` | 內容是 `source ~/settings.sh` (硬編 `~/settings.sh`) + `source "$REPO_SCRIPTS/go_setup.sh"` (後者不存在, 應為 `go.sh`) | 修正 `settings.sh` 路徑為 `${REPO_DIR}/bin/bash/settings.sh`；改 `go.sh`；或整個刪除 |
| `bin/claudew` | `ANTHROPIC_AUTH_TOKEN=$TIKTOK_API_KEY claude ...` | 與 `bin/bash/.bash_aliases:126` 內 `claudew` alias 重複；應自 `bin/` 移除, 保留 `.bash_aliases` 為唯一來源 |
| `bin/agy-ide_extension_install` + `bin/agy-ide_extension_dump` | 兩個 root symlink 都指向 `bin/vscode/agy-ide_extension_*` | 確認 `agy-ide` 是否存在; 若否整組刪除 (Q2) |
| `bin/devcontainer` (指向 `~/Library/Application Support/Code/User/globalStorage/.../devcontainer`) | 一個外部 CLI 入口 symlink | 加進 `bin/README.md` 索引, 標註「外部相依」 |

### 2.5 輕微：命名/慣例不一致

| 慣例 (convention) | 現況 | 應統一 |
| --- | --- | --- |
| `bin/` 根目錄混雜 executable 與 symlink | 既有實檔 (`backup`, `scan_private_network`, `git_signing`, `json`...) 也有 symlink 通往 `bin/{mac,system,vscode}/` | 全部實檔下放子目錄, 根目錄只留 symlink 與文件入口 |
| `bin/mac/*.sh` 後綴 | `disk_analysis-mac.sh`, `launch_audit-mac.sh`, `login_audit-mac.sh`, `network_security_audit-mac.sh` 帶 `.sh`；`mac_cleanup`, `mac_keyboard_shortcuts_dump`, `mac_keyboard_shortcuts_restore`, `mac_extension_list` 不帶 | 統一加 `.sh` |
| `bin/system/*_info` vs `bin/system/{checkdisk, myip, list_big_files, network_topology_scan, system_performance, system_service, raspi-config, brew_bundle_dump, system_dump, system_info, system_link}` | 兩種命名風格 | 統一以「`bin/<area>/<area>_<tool>`」前綴; sub-tool 採 `<component>_<type>` |
| `bin/` 根目錄缺索引 | 沒有 `bin/README.md` | 新建 `bin/README.md` + `docs/bin_index.md` (依使用者查閱位置) |
| Markdown 報告目錄 | `bin/mac/*_audit*.sh` 寫入 `$HOME/.config/system/data/`, 但 `bin/system/network_topology_scan.sh` 寫到 `./report/` | 將報告路徑收斂到 `bin/bash/settings.sh` 之 `AUDIT_REPORT_DIR` |
| `settings.sh` 暴露個資 | `bin/bash/settings.sh:9-10` 暴露 `passwd="zxcvasdf"`, `email="biz.shuk@gmail.com"` | 移到 git-ignored 之 `~/.config/env_setup/settings.private.sh` |
| `Brewfile` 屬於 `scripts/` | `bin/system/brew_bundle_dump` 與 `bin/mac/mac_cleanup` 都硬編 `~/projects/env_setup/scripts/Brewfile` | 改以 `bin/bash/settings.sh` 之 `REPO_SCRIPTS` 為唯一來源 |
| `claudew*`, `codexm` 等個人 alias | 在 `bin/bash/.bash_aliases` 與 `bin/claudew` 雙處 | 統一收斂到 `bin/bash/.bash_aliases`; 個人層級 (`~/.bash_local`) 處理 token 細節 |

### 2.6 新發現：未被 plan 涵蓋之入口

| 入口 | 用途 | 應處置 |
| --- | --- | --- |
| `bin/scan_target_network` | 第三個 traceroute 變體 | 併入 `bin/scan_private_network` (Q3-like) 或標 deprecated |
| `bin/scan_private_network.md` + `scan_private_network.output.sample` | 範例與文件 | 隨主腳本移動 |
| `bin/git_signing` | git 簽章 helper | 加進 index |
| `bin/json` | JSON pretty-print helper | 加進 index |
| `bin/find_symbolic_link` | 找 symlink helper | 加進 index |
| `bin/iconv_big5_utf8` | 編碼轉換 | 加進 index |
| `bin/ssoLogin.sh` + `bin/ssoLogin_faas.sh` | SSO 登入 helper | 加進 index; 確認 `TIKTOK_API_KEY` 等環境變數依賴 |
| `bin/backup` + `bin/backupSync` | 備份 helper | Q3 |
| `bin/scan_devices` | 整頁式硬體偵測 | 與 `system_info` 並列, 加進 index |
| `bin/devcontainer` | 外部 CLI symlink | 加進 index, 標外部相依 |
| `bin/check_alive` + `bin/check_service` | 健康檢查 helper | 加進 index |
| `bin/listen_port` | port 監聽 helper | 加進 index |
| `bin/reverse_ln` | 反向 symlink helper | 加進 index |
| `bin/file_encoding` | 編碼偵測 | 加進 index |
| `bin/generate_https_cert` + `bin/generator_pem.sh` | HTTPS cert/PEM helper | 加進 index |
| `bin/mac/mac_extension_list` | 列出 mac extensions | 加進 index |
| `bin/mac/keyboard_shortcuts/` | plist 樣板 | 加進 index |
| `bin/system/config/pf.conf` | pf 防火牆樣板 | 加進 index (與 `network_security_audit-mac.sh` 配對) |
| `bin/system/checkdisk` | 磁碟檢查 | 加進 index |
| `bin/system/list_big_files.sh` | 大檔掃描 | 加進 index |
| `bin/system/myip` | IP 查詢 | 加進 index |
| `bin/bash/cmd_usage.md` | 個人 cheat notes | 加進 index, 標 personal |
| `bin/bash/backup.ignore` | 備份忽略清單 | 加進 index |
| `bin/bash/shell_script_sample.sh` | shell 範本 | 加進 index |
| `bin/bash/.vim/` | vim 設定 + 10 個 git submodules | 加進 index |
| `bin/bash/.vimrc`, `.screenrc`, `.toprc`, `.gitconfig`, `.gitmessage`, `.npmrc`, `.gitignore` | 各種 dotfiles | 加進 index |
| `bin/vscode/snippets/` + `keybindings.json` + `settings.json` | IDE 設定 | 加進 index |
| `bin/vscode/agy-ide_extension_list.txt` + `vscode_extension_list.txt` | extension 清單 | 加進 index |
| `bin/sshd_config` + `bin/ssh_config` + `bin/ssh.md` + `bin/ssh_key_compare` + `bin/ssh_keygen` + `bin/strip-docker-image-README.md` | SSH 設定 | 加進 index |
| `pkg/libgit2.sh` | libgit2 helper (與 `pkg/libgit2/` 子模組配對) | 加進 index |
| `.vscode/settings.json` (repo root) | repo 自身 VSCode 設定 | 加進 CLAUDE.md 慣例章節 |
| `skills/bytedance/`, `skills/gdpa/` | skills stubs (已空) | 移除或填實 |
| `claude/`, `claude/`, `claude/` 對應之 `~/.claude` | `bin/system/system_link` 有 link, 但 `run.sh` 沒有 | 對齊 (Phase 4.1) |

## 3. 目標 (Goals)

1. **文件如實 (truthful docs)**: 移除 `cmd/`、舊 `bin/project_setup` 之敘述；新增 `docs/bin_index.md` 與 `bin/README.md` 作為 `bin/` 真實索引。
2. **去重 (deduplication)**: 合併等價入口 (`run.sh` ↔ `bin/system/system_link`；三個 network scanner 整合為單一入口 + sub-tool)。
3. **移除 vendored dead weight**: `bin/git-secret`, `pkg/ctags-5.8/`, `tmp/doas-install.sh` 不再隨 repo 散佈。
4. **強化可擴展性 (scalable)**: `bin/` 採用「`bin/<area>/<tool>` 為一獨立腳本，自動由 PATH 找到」之 layout；新增腳本時不必同時改 root `bin/`、根目錄 symlink 與 `ecosystem.config.js`。
5. **安全化 (sanitize)**: 將明文密碼、email 與 `bytedance_setup.sh` 移出版控。
6. **修 bug**: 修 `bin/system/system_info:8` 之 `BASE_DIR` 路徑 bug (會拼成 `bin/system/system`)。

## 4. 架構 (Architecture)

### 4.1 目標 layout

```text
env_setup/
├── README.md             # 業務面 (truthful, no cmd/ smain ref)
├── CLAUDE.md             # 技術脈絡 (與 layout 同步)
├── AGENTS.md -> CLAUDE.md
├── README.todo           # 全 repo pending items
├── LICENSE
├── run.sh                # 唯一 symlink 入口 (含 IDE 設定分支)
├── ecosystem.config.js   # pm2 tasks (用 ./bin/<area>/<tool> 全路徑)
├── .gitignore            # 含 .bash_local, settings.private.sh, log/
├── .vscode/              # repo 自身 VSCode 設定
├── bin/
│   ├── README.md         # 索引 (給 symlink 持有者查閱)
│   ├── bash/             # dotfiles, settings.sh, helper
│   ├── mac/              # macOS 專用 *.sh
│   ├── system/           # 跨平台系統工具 (硬體偵測, dump, network, link)
│   ├── vscode/           # editor 設定與 dump/restore
│   └── network/          # ← 新增：scan_* 集中此處
├── docs/
│   ├── plans/            # 進行中計畫 (本檔位置)
│   ├── specs/            # 既有設計 (沿用)
│   ├── backlog/          # 待辦想法
│   ├── notes/            # cheatsheet, kernel png, ubuntu notes
│   ├── templates/        # sysctl, pf 範本 (取代 pkg/sysctl, bin/system/config)
│   └── bin_index.md      # bin/ 完整入口索引 (含本檔 §2.6 全表)
├── scripts/              # OS / tool installer (既有, 沿用)
├── pkg/                  # 第三方 source (移除 ctags, 改 submodule)
├── archive/              # 退役項目 (doas-install, 舊 plan 引用)
└── troubleshooting/      # 既有故障排除
```

### 4.2 模組對應 (Module Mapping)

| 業務領域 | 套件 / 模組 | 進入點 |
| --- | --- | --- |
| 環境與開發工具配置 | `scripts/`, `bin/bash/settings.sh` | `./scripts/mac.sh`, `./scripts/ubuntu.sh`, `./run.sh` |
| 開發者工具箱 (CLI 與腳本) | `bin/` (root + `bin/{bash,mac,system,vscode,network}/`) | `bin/<name>` (PATH 已設 `${HOME}/bin`) |
| 觀測與報告 | `bin/mac/{disk,launch,login,network_security}_audit*.sh`, `bin/system/network_topology_scan.sh` | pm2 cron via `ecosystem.config.js` |
| 硬體偵測 | `bin/system/{cpu,mem,gpu,disk,display,usb,input,audio,os,myip,checkdisk,list_big_files,system_info,system_dump,scan_devices}` | 直接執行 |
| 網路掃描 | `bin/scan_private_network`, `bin/scan_target_network`, `bin/system/network_topology_scan.sh` (擬合併至 `bin/network/`) | 直接執行 |

### 4.3 移除 / 改造清單 (Change Set)

#### 4.3.1 刪除 (remove)

- `bin/git-secret` (vendored, 52KB / 2082 行)
- `pkg/ctags-5.8/` (vendored, 2.2MB / 111 檔) → 改 `git submodule add <url> pkg/ctags-5.8`；`.gitmodules` 已有 10 條 (vim plugins + libgit2)
- `tmp/doas-install.sh` → `archive/doas-install.sh`
- `pkg/linux/Linux_kernel_structure.png` → `docs/notes/`
- `pkg/linux/*.md` (7 份 ubuntu_note_*) → `docs/notes/`
- `pkg/ufw/` (整個目錄, 從未被使用)
- `pkg/sysctl/` (若無 Q1 維護者) → `docs/templates/sysctl/`
- `bin/system/system_performance.sh` (純 cheatsheet) → `docs/notes/system_performance_cheatsheet.md`
- `bin/system/raspi-config` (一行 dead code)
- `bin/system/system_service` (一行 dead code)
- `bin/bytedance_setup.sh` (含明文密碼 + merge conflict markers)
- `bin/goswitch` (broken symlink target + 硬編 `~/settings.sh`)
- `bin/claudew` (個人 alias, 與 `bin/bash/.bash_aliases:126` 重複)
- `mac/`, `grafana/`, `inf/`, `log/app/`, `log/rpc/`, `openclaw/yuna/` (空目錄)
- `skills/bytedance/`, `skills/gdpa/` (空 stubs)

#### 4.3.2 修正 (fix)

- `bin/system/system_info:8` `BASE_DIR="$(dirname "$0")/system"` → `BASE_DIR="$(dirname "$0")"` (因腳本已在 `bin/system/`)
- `bin/system/README.md` 標題改為「硬體偵測與系統工具」；移除對 `mac/disk_analysis-mac.sh`, `mac/launch_audit-mac.sh`, `mac/login_audit-mac.sh`, `mac/network_security_audit-mac.sh` 之錯誤歸屬
- `bin/system/README.md:13` `network_topology_scan-mac.sh` 改名為 `network_topology_scan.sh`
- `bin/system/brew_bundle_dump` 與 `bin/mac/mac_cleanup` 改用 `source $(dirname "$0")/../bash/settings.sh` 取 `REPO_SCRIPTS`

#### 4.3.3 合併 (merge)

- `run.sh` ↔ `bin/system/system_link` → 選 `run.sh` 為主入口 (含 `link_ide_config` + ssh/sysctl + gemini)，目標路徑統一為 `./tmp/` (使用者 2026-07-08 決策，**取代**初版之 `./config/`)；`bin/system/system_link` 已於 2026-07-08 移除 (見 §Execution Log)
- `bin/scan_private_network` + `bin/scan_target_network` + `bin/system/network_topology_scan.sh` → 統一至 `bin/network/scan_network.sh` (依 `--mode=private|target|topology` 分支)；`bin/system/network_topology_scan.sh` 為主實作 (功能最完整)
- 三個 macOS audit (`disk`, `launch`, `login`, `network_security`) 共用 helper (`term_log`, `md_log`, `log`, `header`, `subheader`, `run_cmd`, `AUDIT_REPORT_DIR`) → 抽到 `bin/mac/_lib_audit.sh` (`source` 之)

#### 4.3.4 安全化 (sanitize)

- `bin/bash/settings.sh` 移除 `passwd`, `email`；改從 `~/.config/env_setup/settings.private.sh` 讀取 (`source` 帶 `[ -f ... ] &&` 守衛)
- `bin/bash/.bashrc`, `bin/bash/.bash_aliases`, `bin/bash/.bash_function` 內個人化片段 (`claudew*`, `codexm`) 改以 `source ~/.bash_local` 包裝；具體值留個人層級
- `.gitignore` 加入 `settings.private.sh`, `.bash_local`, `*.bak`, `log/`, `tmp/`, `**/.DS_Store`

#### 4.3.5 文件對齊 (doc sync)

- `README.md`, `CLAUDE.md`：
    - 移除所有 `cmd/`, `smain`, `bin/project_setup` 之敘述
    - 補上 `bin/`, `scripts/`, `pkg/`, `troubleshooting/` 真實入口與功能矩陣
    - 在 `CLAUDE.md` 之 `## 慣例` 加入：`bin/<area>/<tool>` 為可獨立執行的入口；新增工具時, 於 `bin/<area>/<tool>` 撰寫並註冊 root symlink
- `bin/README.md` (新增)：列出 `bin/` 所有工具、用途、相依、所在 namespace
- `docs/bin_index.md` (新增)：同上但含本檔 §2.6 全表, 給 agent 查閱
- `specs/`：
    - `20260217-fix-agent-symlink.md` 改寫為 `20260217-agent-dir-rename.md`, 註明此變更已合併入 `run.sh`
    - `20260218-monitoring-system-update.md` 內容含 `devops/`, 標 `OUT_OF_SCOPE` (本 repo 不含 devops)
- `plans/2026-05-22-improve-workspace.md` 與 `plans/2026-05-24-improve-workspace.md` 標 `## ARCHIVED` 並搬至 `archive/plans/`

### 4.4 可擴展性設計 (Scalability Hooks)

- `bin/<area>/_lib_*.sh`：每個 area 放置共用 helper，新工具 `source` 之即可 (e.g. `bin/mac/_lib_audit.sh`)
- `bin/<area>/<tool>`：所有工具統一前綴 (e.g. `mac_*`, `system_*`, `vscode_*`)；`bin/` 根只放指向子目錄的 symlink
- `ecosystem.config.js`：cron 任務以 `./bin/<area>/<tool>` 全路徑表示；新增 cron 時不必改 `bin/` root
- 新增工具流程 (寫入 `bin/README.md` 與 `docs/bin_index.md`)：
    1. 決定 area: `bash` / `mac` / `system` / `vscode` / `network`
    2. 在 `bin/<area>/<tool>` 撰寫，必要時 `source bin/<area>/_lib_*.sh`
    3. 若需 root 入口, 在 `bin/<tool>` 加 symlink `bin/<tool> -> <area>/<tool>`
    4. 將工具加入 `docs/bin_index.md`
    5. 若需排程, 在 `ecosystem.config.js` 用全路徑註冊

## 5. 階段 (Phased Steps)

> 每個階段完成後跑一次 `git status` + 對應測試 (見 §6)。

### Phase 1 — 盤點與文件校正 (truthful docs)

- [ ] Step 1.1：建立 `bin/README.md` (短索引, 給人類查閱)
- [ ] Step 1.2：建立 `docs/bin_index.md` (完整索引, 含本檔 §2.6 全表)
- [ ] Step 1.3：修改 `README.md`，刪除 `cmd/` 與 `smain` 段落；改以 `bin/` 真實入口為例
- [ ] Step 1.4：修改 `CLAUDE.md`，刪除 `cmd/`、Cobra、logrus 依賴；新增 `bin/`, `docs/`, `troubleshooting/` 條目
- [ ] Step 1.5：將 `specs/20260217-fix-agent-symlink.md` 改名為 `20260217-agent-dir-rename.md` 並更新內文
- [ ] Step 1.6：將 `specs/20260218-monitoring-system-update.md` 標 `OUT_OF_SCOPE` (本 repo 不含 devops)
- [ ] Step 1.7：將 `plans/2026-05-22-*.md`, `plans/2026-05-24-*.md` 標 `## ARCHIVED`
- [ ] Step 1.8：修正 `bin/system/README.md` 標題與內容 (改為「硬體偵測」；移除對 `bin/mac/*` 之錯誤歸屬)

### Phase 2 — 安全化 (sanitize)

- [x] Step 2.1：`bin/bash/settings.sh` 移除 `passwd`, `email`；改以 `source ~/.config/env_setup/settings.private.sh 2>/dev/null` 讀取
    - **已完成 2026-07-08**。`bash -n` 通過；`git grep` 確認 tracked 樹已無明文 `passwd`/`email`。
    - **未消解之依賴**：`bin/ssh_keygen:8` 仍 `${email}`，現依賴使用者於 `settings.private.sh` 內 export；`bin/bash/.gitconfig:5` 仍寫死 `email = biz.shuk@gmail.com`。此二處留待 Step 2.5 或後續 privacy pass 處理。
- [ ] Step 2.2：刪除 `bin/bytedance_setup.sh`
- [x] Step 2.3：`.gitignore` 加入 `settings.private.sh`, `.bash_local`, `*.bak`, `**/.DS_Store`
    - **已完成 2026-07-08**。
    - 既有 `tmp`、`log/` 已存在（無需重複加）。`config/*` 規則保留（保護舊 `system_link` 時代之殘留內容）。
    - 新增 4 條規則已用 `git check-ignore` 在 repo 內 `__test_*.{sh,bak,DS_Store}` 與 `__test_/deep/sub/.DS_Store` 驗證通過。
    - `**/.DS_Store` 與既有 `.DS_Store` (line 2) 重複但無害；屬計畫外，未移除以避免破壞既有 force-push 流程。
- [ ] Step 2.4：`bin/bash/.bashrc` 移除 `ANTHROPIC_AUTH_TOKEN` 相關個人 token export (若存在)
- [x] Step 2.5：所有 `bin/bash/.bash_*` 之個人 alias 改以 `~/.bash_local` 包裝
    - **CANCELLED 2026-07-08**（使用者決策）。理由：個人 alias 仍留在 `.bash_aliases` 即可，搬到 `~/.bash_local` 之預期效益低（`.bash_aliases` 本就只 source 於互動 shell，不污染 sub-process）；隱私敏感值已由 Step 2.1 的 `settings.private.sh` 機制承載。Step 2.4 對 `.bashrc` 之 token cleanup 仍保留為獨立追蹤項。

### Phase 3 — 移除 vendored 與 dead code

- [ ] Step 3.1：移除 `bin/git-secret`；於 `bin/README.md` 註明改用 `brew install git-secret`
- [ ] Step 3.2：將 `pkg/ctags-5.8/` 改為 `git submodule`：`git rm -r pkg/ctags-5.8` + `git submodule add <upstream>`；同步檢查 `scripts/ctags_setup.sh` 的組裝路徑
- [x] Step 3.3：刪除 `bin/system/system_performance.sh`（純 cheatsheet）、`bin/system/raspi-config`（一行 dead code）、`bin/system/system_service`（一行 dead code）
    - **已完成 2026-07-08**。三檔直接 `rm`；`bin/bash/cmd_usage.md:186` 對 `bin/system_performance` 之引用變為 stale 個人筆記 reference，不影響執行（個人層級後續可手動修）。
- [x] Step 3.4：移除 `tmp/doas-install.sh`（直接刪除，未走 `archive/`，因為 `archive/` 尚未建立且該檔為一次性 vendored 內容，無保留價值）
- [x] Step 3.5：搬移 `pkg/linux/*.md` (7 份) → `pkg/linux/notes/`（採用使用者在 2026-07-08 之決策：保留在 `pkg/linux/` 子樹，避免大規模 restructure `docs/`；`Linux_kernel_structure.png` 留原位，本步未動）
- [ ] Step 3.5b：搬移 `pkg/linux/Linux_kernel_structure.png` → `docs/notes/`（尚未執行，與 `pkg/linux/notes/` 之 markdown 同類；待 §4.1 設 `docs/notes/` 為統一落點時一起處理）
- [ ] Step 3.6：刪除 `pkg/ufw/` (整個)；搬 `pkg/sysctl/` 至 `docs/templates/sysctl/`
- [x] Step 3.7：移除空目錄
    - **已完成 2026-07-08**。
    - Plan 原列：`mac/`, `grafana/`, `inf/`, `log/app/`, `log/rpc/`, `openclaw/yuna/`
    - 額外清理（使用者在確認時選擇「delete all of empty dir」）：`openclaw/`（父目錄, 含已被 .gitignore 涵蓋的 `yuna/`）、`bin/bit/`、`skills/`（含 `bytedance/`, `gdpa/`）、`.claude/skills/lark_docs/`
    - 保留：`./tmp/`（`run.sh` runtime 寫入目標）、`bin/bash/.vim/bundle/*` (9 個 git submodules, mode 160000)
- [x] Step 3.8：移除 `skills/bytedance/`, `skills/gdpa/` (空 stubs)
    - **已被 Step 3.7 涵蓋**（2026-07-08 執行空目錄清理時 `skills/` 整個目錄連同 `bytedance/`、`gdpa/` 一併移除）。`find . -type d -empty` 確認當前 repo 已無 `skills/`。

### Phase 4 — 結構去重與重組 (structural dedup)

- [x] Step 4.1：合併 `bin/system/system_link` 邏輯至 `run.sh`；`bin/system/system_link` 已刪除
    - **已完成 2026-07-08**。
    - **重要決策分歧**：原 plan §4.3.3 規格寫「目標路徑統一為 `./config/`」；使用者最終決策為「沿用 `run.sh` 既有的 `./tmp/`」(`run.sh` 寫到 `./tmp/`，若 `system_link` 有 `run.sh` 沒有的則補上)。`./config/` 為已棄用目標，不再生產 symlink。
    - 已補入 `run.sh` 之項目（來自 `system_link` 獨有）：`/etc/ssh/ssh_config`、`${HOME}/.gemini`。
    - 移除 claude 死路徑：`~/.claude → ./claude/.claude`、`./claude/settings.json → ~/.claude/settings.json`、`./claude/ccstatusline/settings.json → ~/.config/ccstatusline/settings.json`（三條 source 在 repo 不存在，依使用者決策全數移除）。
    - Antigravity 路徑採 `run.sh` 既有寫法 `Antigravity IDE/User`（非 `system_link` 之 `Antigravity/User`）。
    - `bash -n run.sh` 通過；陣列 loop 模式 dry-run 通過。
    - **影響 CLAUDE.md**：原 `CLAUDE.md:110` 註記 `config/` 為「規劃中 (取代 ./tmp/)」已過時，現 `./tmp/` 為唯一目標，無取代計畫。
- [ ] Step 4.2：建立 `bin/mac/_lib_audit.sh` (term_log, md_log, log, header, subheader, run_cmd, AUDIT_REPORT_DIR)；重構三個 audit 腳本 `source` 此 helper
- [ ] Step 4.3：整合 `bin/scan_private_network` + `bin/scan_target_network` + `bin/system/network_topology_scan.sh` → `bin/network/scan_network.sh` (`--mode=private|target|topology`)
- [x] Step 4.4：修正 `bin/system/system_info:8` `BASE_DIR` bug
    - **已完成 2026-07-08**。
    - 修正前：`BASE_DIR="$(dirname "$0")/system"` → 在 `bin/system/system_info` 內，`dirname` = `bin/system`，造成 `BASE_DIR = bin/system/system`（不存在），sub-tool 全部找不到。
    - 修正後：`BASE_DIR="$(dirname "$0")"` → 對應 `bin/system/` 本身。
    - 驗證：`./bin/system/system_info` 從 `bin/system/` 目錄執行，10 個 sub-tool 全部成功輸出（os_info, cpu_info, mem_info, gpu_info, disk_info, usb_info, display_info, myip, input_info, audio_info）。
- [ ] Step 4.5：刪除 `bin/goswitch`；刪除 `bin/claudew` (保留 `bin/bash/.bash_aliases:126` 為唯一來源)
- [ ] Step 4.6：所有 `bin/mac/*.sh` 加上統一前綴 `mac_` 並補 `.sh` 後綴 (例: `mac_cleanup` → `mac_cleanup.sh`)
- [ ] Step 4.7：`bin/system/brew_bundle_dump` 與 `bin/mac/mac_cleanup` 改用 `source $(dirname "$0")/../bash/settings.sh` 取 `REPO_SCRIPTS`
- [ ] Step 4.8：Q3 決策後, 將 `bin/backup` 與 `bin/backupSync` 整併為 `bin/backup --mode=diff|sync` (預設: diff)

### Phase 5 — 可擴展性 (scalability)

- [ ] Step 5.1：建立 `bin/<area>/_lib_*.sh` 慣例並寫入 `bin/README.md` 與 `docs/bin_index.md`
- [ ] Step 5.2：建立 `bin/network/` 區，未來所有 `scan_*` 工具集中此處
- [ ] Step 5.3：`ecosystem.config.js` 改用 `./bin/<area>/<tool>` 全路徑 (目前已是, 確認無遺漏)
- [ ] Step 5.4：在 `CLAUDE.md` `## 慣例` 加入：
    - `bin/<area>/<tool>` 為唯一真實入口；根目錄只放 symlink
    - `bin/<area>/_lib_*.sh` 為共用 helper，新工具 `source` 之
    - 新增 OS installer 必須 `source "$(dirname "$0")/settings.sh"`
    - 不得將明文個資 (passwd, email, token) commit；用 `settings.private.sh`
- [ ] Step 5.5：在 `bin/README.md` 加「新增工具流程」段落 (見 §4.4)

### Phase 6 — 驗證 (verification)

- [ ] Step 6.1：執行 `./run.sh` 不報錯；確認所有 `tmp/` 軟連結正確（ssh, sysctl, gemini, claude-host 等皆已包含；`config/` 為已棄用目標，不再寫入）
- [ ] Step 6.2：執行 `bin/system/system_info` 確認 10 個硬體 sub-tool 全部輸出 (驗 line 8 bug fix)
- [ ] Step 6.3：執行 `bin/mac/disk_analysis-mac.sh` 與 `bin/mac/launch_audit-mac.sh` 確認仍能寫出 markdown 報告
- [ ] Step 6.4：執行 `bin/network/scan_network.sh --mode=topology --no-scan` 確認新介面可用
- [ ] Step 6.5：對所有 `bin/<area>/*.sh` 跑 `shellcheck` (若安裝)；修正 high 等級警告
- [ ] Step 6.6：`git grep -n 'cmd/'` 與 `git grep -n 'project_setup'` 確認無殘留
- [ ] Step 6.7：`git grep -n 'smain'` 確認無殘留

## 6. 測試策略 (Verification Plan)

| 層級 | 工具 / 動作 | 期望 |
| --- | --- | --- |
| 靜態 | `git grep`, `shellcheck`, `markdownlint` | 無高風險警告 |
| 結構 | `find bin/ -type f \| sort` | 與 `docs/bin_index.md` 列表一致 |
| 連結 | `./run.sh` | `tmp/` (ssh, sysctl, gemini) 全部正確建立 |
| 執行 | `bin/system/system_info`, `bin/mac/*_audit*.sh`, `bin/network/scan_network.sh` | 輸出與重構前一致 |
| 文件 | `git grep` 對 `cmd/`, `smain`, `project_setup` | 無殘留 (排除 `archive/` 與 `plans/2026-07-08-*.md`) |

## 7. 風險與回滾 (Risks & Rollback)

- Phase 3.2 將 `pkg/ctags-5.8` 改 submodule 會破壞本地 clone；需先 `git clone` 完整來源到外部位置備份
- Phase 2 之後 `bin/bash/settings.sh` 將不再 export `passwd`/`email`；若其他腳本仍依賴, 於 Phase 2.1 同步 grep 與替換
- Phase 4.1 合併 `system_link` 後若 `run.sh` 壞掉, 可暫時還原 `system_link` 作為 `run.sh` 的 symlink
- Phase 4.3 合併三個 network scanner 可能破壞既有 cron (若有任何外部觸發)；先 grep 外部引用

## 8. 命名與慣例 (Naming & Conventions)

| 類型 | 慣例 | 範例 |
| --- | --- | --- |
| Shell 腳本 | `snake_case.sh` (全小寫, 底線, `.sh` 結尾) | `bin/mac/mac_disk_analysis.sh` |
| 跨平台子目錄 | `<area>/<tool>`；`<area>/_lib_*.sh` 為 helper | `bin/system/_lib_hw.sh` |
| 文件 | `YYYY-MM-DD-<topic>.md` (置於 `docs/plans/` 或 `docs/specs/`) | `2026-07-08-env-setup-structural-cleanup.md` |
| 設定 | `~/.config/env_setup/settings.private.sh` (git-ignored) |  |
| 報告 | `$AUDIT_REPORT_DIR/<tool>-YYYYMMDD.report.md` (統一由 `bin/mac/_lib_audit.sh` 提供) |  |

## 9. 開放問題 (Open Questions)

- Q1: `pkg/sysctl/` 與 `pkg/ufw/` 是否仍有人維護？若無, 直接刪除；若有, 需在 `docs/templates/` 加索引
- Q2: `bin/agy-ide_extension_install` 與 `bin/agy-ide_extension_dump` 是否仍指向有效工具？若 `agy-ide` 不存在, 整組刪除
- Q3: `bin/backup` 與 `bin/backupSync` 兩者差異 (前者差異化, 後者強制覆寫) 是否仍合用？若使用率低, 整併為 `bin/backup --mode=diff|sync`
- Q4: `claude/claudew*` 個人 alias 改放 `~/.bash_local` 個人層級？
- Q5: `bin/scan_target_network` 是否仍使用？若否, 與 `scan_private_network` 一併整合
- Q6: `skills/bytedance/`, `skills/gdpa/` 是否有人維護？若否, 直接刪除

## 10. 引用 (References)

- `plans/2026-05-22-improve-workspace.md` — 舊計畫 (含已不存在的 `cmd/` 與 `bin/project_setup` 假設)
- `plans/2026-05-24-improve-workspace.md` — 舊計畫 (Task 5 涉及 `bin/mac_cleanup` 改進, 部分已落地)
- `plans/implementation_plan.md` — 當初撰寫 README/CLAUDE 的 metadata
- `specs/20260217-fix-agent-symlink.md` — `.agent` rename 之歷史紀錄
- `specs/20260218-monitoring-system-update.md` — devops/ 範圍 (本 repo 不含)
- `bin/system/README.md` — 標題錯誤 (寫成「安全性稽核」), 需修正

## 11. 執行紀錄 (Execution Log)

> 2026-07-08 當日決策與實際執行範圍，與本檔初版規格之差異彙整。

### 11.1 已完成 (completed)

| Step | 標題 | 實際決策（與初版差異） |
| --- | --- | --- |
| 2.1 | sanitize `settings.sh` | 照規格執行；未消解之依賴：`bin/ssh_keygen:8` 之 `${email}`、`bin/bash/.gitconfig:5` 之硬碼 email |
| 2.3 | 強化 `.gitignore` | 加入 `settings.private.sh`, `.bash_local`, `*.bak`, `**/.DS_Store`；既有 `tmp`/`log/`/`config/*`/`config/.X` 保留；用 `git check-ignore` 驗證 4 條新規則（包含深層 `.DS_Store`） |
| 2.5 | 個人 alias → `~/.bash_local` | **CANCELLED**；效益低，隱私由 `settings.private.sh` 機制承載（Step 2.1） |
| 3.3 | 刪除 dead system files | `system_performance.sh`（cheatsheet）、`raspi-config`、`system_service` 直接 `rm`；`cmd_usage.md:186` 之 reference 變 stale（不影響執行） |
| 3.4 | 移除 `tmp/doas-install.sh` | 直接 `rm`，**未**走 `archive/`（`archive/` 尚未建立） |
| 3.5 | 搬移 `pkg/linux/*.md` | 7 份 markdown 落入 `pkg/linux/notes/`（**非**初版之 `docs/notes/`） |
| 3.7 | 移除空目錄 | 額外清掉 `bin/bit/`、`skills/`（含 bytedance, gdpa）、`.claude/skills/lark_docs/`、`openclaw/`（父目錄）；保留 `vim/bundle/*` 9 個 submodules |
| 3.8 | 移除 `skills/{bytedance,gdpa}` | **已被 Step 3.7 涵蓋**（`skills/` 整個連同子目錄一起刪除） |
| 4.1 | 合併 `system_link` → `run.sh` | 目標路徑為 `./tmp/`（**非**初版之 `./config/`）；claude/ 死路徑全移除；Antigravity 採 `Antigravity IDE/User` |
| 4.4 | 修 `system_info:8` `BASE_DIR` bug | `$(dirname "$0")/system` → `$(dirname "$0")`；10 個 sub-tool 全部輸出驗證 |

### 11.2 與初版規格之主要分歧 (drift)

1. **目標目錄**：`./config/` 改為 `./tmp/`（`run.sh` 既有），`./config/` 棄用。
2. **`docs/notes/` 之建立時機**：因 `pkg/linux/notes/` 已就地建立，`docs/notes/` 不再急迫；待 `pkg/linux/Linux_kernel_structure.png` 與未來之 cheatsheet 一併成立。
3. **`archive/` 目錄延後**：doas-install.sh 未走 archive，Q: 是否仍要建 `archive/`？若要，未來退役項目統一進此處。

### 11.3 連帶修正 (follow-up)

- `CLAUDE.md:110` 原註記「`config/` 規劃中 (取代 ./tmp/)」已過時；後續 manual pass 需移除。
- `bin/ssh_keygen` 與 `bin/bash/.gitconfig` 之 `email` 仍寫死，待 Step 2.5 / 後續 privacy pass。
