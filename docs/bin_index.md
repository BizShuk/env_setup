# `bin/` 完整索引 (Full Entry Point Catalog)

> `bin/` 內的 scripts 經 `~/bin` symlink 後可直接以 bare name 呼叫；manifest sync、Codex uninstall、macOS cleanup、system information 與 network scan 已移至 root Go CLI 的 `env_setup install` / `env_setup uninstall` / `env_setup dump` / `env_setup cleanup` / `env_setup system` / `env_setup network`。

## 1. `bin/bash/` — dotfiles 與設定

| 項目                          | 類型        | 說明                                                                  |
| ----------------------------- | ----------- | --------------------------------------------------------------------- |
| `settings.sh`                 | 來源檔      | 共用環境變數入口 (`USER_BIN`、`REPO_DIR`、`OS`、`ARCH`)               |
| `.bashrc`                     | dotfile     | 互動式 bash 啟動                                                      |
| `.bash_aliases`               | dotfile     | `claude`、`codex`、`codexm`、`claudep`、`claudew-s`、`claudew-b`、`claudew2` 等 alias；token 變數由 `~/.bash_local` 提供 |
| `.bash_function`              | dotfile     | 共用 shell function                                                   |
| `.bash_logout`                | dotfile     | logout hook                                                           |
| `.gitconfig` / `.gitmessage`  | dotfile     | git 設定 / commit 樣板                                                |
| `.gitignore`                  | dotfile     | 全域忽略                                                              |
| `.vimrc` / `.vim/`            | dotfile     | vim 設定與 9 個 plugin git submodules                                  |
| `.screenrc` / `.toprc` / `.npmrc` | dotfile | screen / top / npm 設定                                                |
| `backup.ignore`               | 設定        | 備份排除清單                                                          |
| `cmd_usage.md`                | 文件        | 個人 cheat notes                                                      |
| `shell_script_sample.sh`      | 樣板        | shell 腳本範本                                                        |

## 2. `bin/mac/` — macOS 專屬

| 項目                              | 說明                                                  |
| --------------------------------- | ----------------------------------------------------- |
| `mac_static_ip.sh`                  | 顯示目前網路與建議固定 IPv4、設定固定 IPv4，並可還原 DHCP 與自動 DNS |
| `launch_audit-mac.sh`             | `LaunchAgents` / `LaunchDaemons` 稽核                 |
| `login_audit-mac.sh`              | 登入帳戶與自動登入設定稽核                            |
| `network_security_audit-mac.sh`   | 通訊埠與服務狀態掃描                                  |
| `mac_keyboard_shortcuts_dump.sh`     | 匯出 macOS 鍵盤快捷鍵 plist                           |
| `mac_keyboard_shortcuts_restore.sh`   | 從 plist 還原快捷鍵                                   |
| `mac_extension_list.sh`              | 列出已安裝副檔名                                      |
| `lib.py` / `ls_sys_path.py`       | python 工具 (副檔名/路徑)                              |
| `sys_path`                        | `ls_sys_path.py` 之系統路徑清單資料                    |
| `keyboard_shortcuts/`             | 鍵盤快捷鍵 plist 樣板                                 |

## 3. Domain Utilities

`env_setup system` 與 `env_setup network` 已直接以 Go 實作 cross-platform probes/scans，不再需要 `bin/` adapter folders。原本混放的其他工具依 ownership 搬至：

| Area | 項目 | 說明 |
| --- | --- | --- |
| `pkg/sysctl/` | `pf.conf` | PF firewall template（非 executable） |
| `scripts/disk/` | `mount_disk.sh` / `mount_disk_by_fstab.sh` | 掛載 helper（非 `bin/` 入口） |

Network scan 入口為 `env_setup network private [target]` 與
`env_setup network target [cidr]`；implementation 位於 `cmd/network/` 與 `svc/network/`。
F3 media validation 入口為 `env_setup system disk verify <volume-path>`；
implementation 位於 `cmd/system/diskVerify.go` 與 `svc/system/diskVerify.go`。
Manifest export 入口為 `env_setup dump mac|vscode-extension|antigravity-extension`；
implementation 位於 `cmd/dump/` 與 `svc/dump/`。
Antigravity extension restore 入口為 `env_setup install antigravity-extension`；
implementation 位於 `cmd/install/` 與 `svc/install/`。
Codex removal 入口為 `env_setup uninstall codex`；default mode 只 preview，
`--apply` 才逐項確認；implementation 位於 `cmd/uninstall/` 與 `svc/uninstall/`。

## 4. `bin/vscode/` — IDE Profile

| 項目                                | 說明                                                |
| ----------------------------------- | --------------------------------------------------- |
| `settings.json` / `keybindings.json` | VSCode 設定                                         |
| `snippets/`                         | 程式碼片段                                          |
| `agy-ide_extension_list.txt` / `vscode_extension_list.txt` | 副檔名清單                                  |

## 5. 根目錄 helper

> 本區為 `bin/` 根目錄下, 跨多業務領域的零碎小工具。新增時以 `bin/<area>/<tool>` 為主, 需要 root-level 入口時再加 symlink。

| 入口                          | 類別              | 說明                                                          |
| ----------------------------- | ----------------- | ------------------------------------------------------------- |
| `json`                        | 開發者 helper     | JSON pretty-print                                              |
| `git_signing`                 | 開發者 helper     | GPG 簽章指引                                                  |
| `git_submodule_master`        | Git helper        | 掃描 `~/projects/*/*` Git repos，fetch 後切換或建立追蹤 `origin/master` 的 local `master` |
| `find_symbolic_link`          | 開發者 helper     | 找出目錄下所有 symlink                                          |
| `iconv_big5_utf8`             | 開發者 helper     | Big5 ↔ UTF-8 編碼轉換                                          |
| `file_encoding`               | 開發者 helper     | 編碼偵測                                                      |
| `reverse_ln`                  | 開發者 helper     | 反向 symlink (來源 → 目標)                                     |
| `generate_https_cert`         | 憑證              | 產生 self-signed HTTPS 憑證                                    |
| `generator_pem.sh`            | 憑證              | 產生 PEM                                                       |
| `backup` / `backupSync`       | 備份              | 備份單檔 / 同步備份                                              |
| `ssoLogin.sh` / `ssoLogin_faas.sh` | 登入          | SSO / FaaS 登入                                                |
| `claudew` / `claudem`         | Claude CLI 包裝 | alias 已升格為實體腳本（commit `38e3556`），引用 `~/.bash_local` 之 token env var；為唯一入口 |
| `ssh_config` / `sshd_config`  | SSH               | ssh client / server 設定                                        |
| `ssh_keygen` / `ssh_key_compare` | SSH            | 產生 / 比對 ssh key（Phase 7.2 `ssh_keygen` 改用 `git config --global user.email` + fallback `noreply@local`） |
| `ssh.md`                      | 文件             | 個人 notes                                                      |
| `strip-docker-image-README.md` | 文件             | docker image README 模板                                        |
| `devcontainer`                | devcontainer      | → 外部 `~/Library/Application Support/Code/User/...` (外部路徑) |
| `mac` / `vscode` / `bash` / `bin` / `utils` | 目錄 | 對應 domain 子目錄（見 §1–§4 + §5.1 Go wrapper） |
| `mac_extension_list.sh` / `mac_keyboard_shortcuts_dump.sh` / `mac_keyboard_shortcuts_restore.sh` | symlink | → `bin/mac/<tool>` 根層便捷入口 |
| `launch_audit-mac.sh` / `login_audit-mac.sh` / `network_security_audit-mac.sh` | symlink | → `bin/mac/<tool>` 根層便捷入口 |
| `backupSync`                  | symlink 相容        | → `bin/backup` 舊名相容, 規劃 git rm                              |
| `_lib_audit.sh`               | symlink             | → `bin/mac/_lib_audit.sh` (Phase 4.2 helper, 3 個 audit script source) |
| `settings.sh`                 | symlink             | → `bin/bash/settings.sh`                                          |
| `file_encoding.sample.csv`    | 樣本                | 編碼偵測範例                                                      |

### 5.1 Go toolchain 鎖版 (Phase 7.7)

> `bin/bin/` 與 `bin/utils/` 為 Go 版本鎖版 wrapper, 透過 symlink 鏈固定到 `~/.local/go1.26.3.darwin-arm64/bin/go`, 避免系統 Go 切換造成專案編譯錯亂。

| 路徑 | 內容 |
| --- | --- |
| `bin/bin/go` | symlink → `../utils/go` |
| `bin/utils/go` | symlink → `${HOME}/.local/go1.26.3.darwin-arm64/bin/go` |

> 兩個 symlink 由 `bin/.gitignore` 排除（machine-local），換機後需自行重建。

> Phase 7 已刪 dead reference：`goswitch`, `bytedance_setup.sh`, `git-secret`, `system_link`, `system_performance.sh`, `raspi-config`, `system_service`, `network_topology_scan.sh`。
> 2026-07-31 (commit `7e9b76e`) 再刪：`check_alive`, `check_service`, `listen_port`, `disk_analysis-mac.sh`, `list_big_files.sh`。

## 6. Network Scan Migration

`bin/network/` 已移除。Network scan domain 由 root Go CLI 的
`env_setup network private|target` 與 `svc/network/` 擁有。

## 加入流程 (Add New Tool)

1. 決定 area: `bash` / `mac` / `vscode`
2. 在 `bin/<area>/<tool>` 撰寫；需要共用 helper 時 `source bin/<area>/_lib_*.sh`
3. 若需 root 入口, 在 `bin/<tool>` 加 symlink `bin/<tool> -> <area>/<tool>`
4. 將工具補入本檔對應分類
5. 若需排程, 在 `ecosystem.config.js` 用 `./bin/<area>/<tool>` 全路徑註冊

## 共用 helper 慣例 (Shared Helper Convention)

跨腳本共用函式 / 樣板 / 常數, 一律放至 `bin/<area>/_lib_<purpose>.sh`,
以底線前綴標明「非直接執行, 僅供 `source`」。

| Helper 檔案 | 用途 | 提供函式 / 常數 |
|---|---|---|
| `bin/mac/_lib_audit.sh` | macOS 稽核腳本共用 | `term_log`, `md_log`, `log`, `header`, `status`, `audit_init` (回填 `REPORT_FILE`) |

使用範例 (`bin/mac/launch_audit-mac.sh`):
```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_lib_audit.sh"
audit_init "launch_audit"
header "1. LaunchAgents 概覽"
log "使用者層級項目: ${COUNT} 筆"
```

## 排程 (Scheduling)

`ecosystem.config.js` 之 `Local` namespace 統一管理本機排程;
`bin/` 內的 script task 必須以 `./bin/<area>/<tool>` 全路徑註冊, 避免 pm2 切換工作目錄後找不到入口;
已安裝於 `PATH` 的 binary (`go`、`env_setup`) 則以 bare name + `args` 陣列註冊。
