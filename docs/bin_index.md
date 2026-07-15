# `bin/` 完整索引 (Full Entry Point Catalog)

> `bin/` 根目錄目前共有 59 個項目 (含目錄、檔案、symlink)。所有檔案經 `~/bin` symlink 後可直接以 bare name 呼叫。

## 1. `bin/bash/` — dotfiles 與設定

| 項目                          | 類型        | 說明                                                                  |
| ----------------------------- | ----------- | --------------------------------------------------------------------- |
| `settings.sh`                 | 來源檔      | 共用環境變數入口 (`USER_BIN`、`REPO_DIR`、`OS`、`ARCH`)               |
| `.bashrc`                     | dotfile     | 互動式 bash 啟動                                                      |
| `.bash_aliases`               | dotfile     | `claudew-s`、`claudew-b`、`claudew2`、`codexm` 等 alias           |
| `.bash_function`              | dotfile     | 共用 shell function                                                   |
| `.bash_logout`                | dotfile     | logout hook                                                           |
| `.gitconfig` / `.gitmessage`  | dotfile     | git 設定 / commit 樣板                                                |
| `.gitignore`                  | dotfile     | 全域忽略                                                              |
| `.vimrc` / `.vim/`            | dotfile     | vim 設定與 10 個 git submodules                                        |
| `.screenrc` / `.toprc` / `.npmrc` | dotfile | screen / top / npm 設定                                                |
| `backup.ignore`               | 設定        | 備份排除清單                                                          |
| `cmd_usage.md`                | 文件        | 個人 cheat notes                                                      |
| `shell_script_sample.sh`      | 樣板        | shell 腳本範本                                                        |

## 2. `bin/mac/` — macOS 專屬

| 項目                              | 說明                                                  |
| --------------------------------- | ----------------------------------------------------- |
| `mac_cleanup.sh`                     | 清理 `/private/var/log`、`~/Library/Caches`、`~/.Trash` |
| `disk_analysis-mac.sh`            | 磁碟與敏感目錄權限稽核                                |
| `launch_audit-mac.sh`             | `LaunchAgents` / `LaunchDaemons` 稽核                 |
| `login_audit-mac.sh`              | 登入帳戶與自動登入設定稽核                            |
| `network_security_audit-mac.sh`   | 通訊埠與服務狀態掃描                                  |
| `mac_keyboard_shortcuts_dump.sh`     | 匯出 macOS 鍵盤快捷鍵 plist                           |
| `mac_keyboard_shortcuts_restore.sh`   | 從 plist 還原快捷鍵                                   |
| `mac_extension_list.sh`              | 列出已安裝副檔名                                      |
| `lib.py` / `ls_sys_path.py`       | python 工具 (副檔名/路徑)                              |
| `keyboard_shortcuts/`             | 鍵盤快捷鍵 plist 樣板                                 |

## 3. `bin/system/` — 跨平台硬體 / 系統偵測

| 項目                            | 說明                                                          |
| ------------------------------- | ------------------------------------------------------------- |
| `system_info`                   | 聚合入口, 一次跑 10 個 sub-tool                                |
| `system_dump`                   | 統一匯出 brew / vscode / agy-ide 套件清單                      |
| `os_info` / `cpu_info` / `mem_info` / `gpu_info` / `disk_info` | 細粒度硬體偵測               |
| `display_info` / `usb_info` / `input_info` / `audio_info`      | 顯示 / USB / 輸入 / 音訊      |
| `myip`                          | 查詢本機對外 IP                                                |
| `checkdisk`                     | 磁碟使用率                                                     |
| `list_big_files.sh`             | 大檔掃描                                                       |
| `brew_bundle_dump`              | 匯出 Brewfile                                                  |
| `uninstall_codex.sh`            | 反安裝 Codex CLI（清理 PATH / config / cache）                |
| `config/`                       | pf 防火牆樣板                                                  |

> Phase 7.1 刪除：`network_topology_scan.sh`（dead path, 已由 `bin/network/scan_network.sh` dispatcher 取代, 見 §6）

## 4. `bin/vscode/` — IDE Profile

| 項目                                | 說明                                                |
| ----------------------------------- | --------------------------------------------------- |
| `settings.json` / `keybindings.json` | VSCode 設定                                         |
| `snippets/`                         | 程式碼片段                                          |
| `agy-ide_extension_install` / `_dump` | Antigravity IDE 副檔名管理                         |
| `vscode_extension_dump`             | VSCode 副檔名匯出                                   |
| `agy-ide_extension_list.txt` / `vscode_extension_list.txt` | 副檔名清單                                  |

## 5. 根目錄 helper (23 個補列入口)

> 本區為 `bin/` 根目錄下, 跨多業務領域的零碎小工具。新增時以 `bin/<area>/<tool>` 為主, 需要 root-level 入口時再加 symlink。

| 入口                          | 類別              | 說明                                                          |
| ----------------------------- | ----------------- | ------------------------------------------------------------- |
| `json`                        | 開發者 helper     | JSON pretty-print                                              |
| `git_signing`                 | 開發者 helper     | GPG 簽章指引                                                  |
| `find_symbolic_link`          | 開發者 helper     | 找出目錄下所有 symlink                                          |
| `iconv_big5_utf8`             | 開發者 helper     | Big5 ↔ UTF-8 編碼轉換                                          |
| `file_encoding`               | 開發者 helper     | 編碼偵測                                                      |
| `reverse_ln`                  | 開發者 helper     | 反向 symlink (來源 → 目標)                                     |
| `check_alive`                 | 健康檢查          | 主機存活偵測                                                   |
| `check_service`               | 健康檢查          | 服務存活偵測                                                   |
| `listen_port`                 | 健康檢查          | 監聽指定 port                                                   |
| `generate_https_cert`         | 憑證              | 產生 self-signed HTTPS 憑證                                    |
| `generator_pem.sh`            | 憑證              | 產生 PEM                                                       |
| `backup` / `backupSync`       | 備份              | 備份單檔 / 同步備份                                              |
| `network/scan_network.sh`     | 網路掃描          | 統一入口, --mode=private\|target\|topology\|topology-no-scan      |
| `ssoLogin.sh` / `ssoLogin_faas.sh` | 登入          | SSO / FaaS 登入                                                |
| `claudew` / `claudem`         | Claude CLI 包裝 | alias 已升格為實體腳本（commit `38e3556`），引用 `~/.bash_local` 之 token env var；為唯一入口 |
| `ssh_config` / `sshd_config`  | SSH               | ssh client / server 設定                                        |
| `ssh_keygen` / `ssh_key_compare` | SSH            | 產生 / 比對 ssh key（Phase 7.2 `ssh_keygen` 改用 `git config --global user.email` + fallback `noreply@local`） |
| `ssh.md`                      | 文件             | 個人 notes                                                      |
| `strip-docker-image-README.md` | 文件             | docker image README 模板                                        |
| `devcontainer`                | devcontainer      | → 外部 `~/Library/Application Support/Code/User/...` (外部路徑) |
| `mac` / `system` / `vscode` / `network` / `bash` / `bin` / `utils` | 目錄 | 對應子目錄（見 §1–§4 + §6 Go wrapper） |
| `mac_cleanup.sh` / `mac_extension_list.sh` / `mac_keyboard_shortcuts_dump.sh` / `mac_keyboard_shortcuts_restore.sh` | symlink | → `bin/mac/<tool>` 根層便捷入口 |
| `disk_analysis-mac.sh` / `launch_audit-mac.sh` / `login_audit-mac.sh` / `network_security_audit-mac.sh` | symlink | → `bin/mac/<tool>` 根層便捷入口 |
| `list_big_files.sh` / `system_dump` / `system_info` / `checkdisk` / `brew_bundle_dump` | symlink | → `bin/system/<tool>` 根層便捷入口 |
| `agy-ide_extension_dump` / `agy-ide_extension_install` / `vscode_extension_dump` | symlink | → `bin/vscode/<tool>` 根層便捷入口 |
| `backupSync`                  | symlink 相容        | → `bin/backup` 舊名相容, 規劃 git rm                              |
| `_lib_audit.sh`               | symlink             | → `bin/mac/_lib_audit.sh` (Phase 4.2 helper, 4 個 audit script source) |
| `settings.sh`                 | symlink             | → `bin/bash/settings.sh`                                          |
| `file_encoding.sample.csv`    | 樣本                | 編碼偵測範例                                                      |

### 5.1 Go toolchain 鎖版 (Phase 7.7)

> `bin/bin/` 與 `bin/utils/` 為 Go 版本鎖版 wrapper, 透過 symlink 鏈固定到 `~/.local/go1.26.3.darwin-arm64/bin/go`, 避免系統 Go 切換造成專案編譯錯亂。

| 路徑 | 內容 |
| --- | --- |
| `bin/bin/go` | symlink → `../utils/go` |
| `bin/utils/go` | symlink → `/Users/shuk/.local/go1.26.3.darwin-arm64/bin/go` |

> Phase 7 已刪 dead reference：`goswitch`, `bytedance_setup.sh`, `git-secret`, `system_link`, `system_performance.sh`, `raspi-config`, `system_service`, `network_topology_scan.sh`。

## 6. `bin/network/` — 統一網路掃描入口 (Phase 4.3 closure)

| 項目                  | 說明                                                       |
| --------------------- | ---------------------------------------------------------- |
| `scan_network.sh`     | 統一 dispatcher, `--mode=private\|target\|topology\|topology-no-scan` |

> Phase 7.1: 已刪除舊 `bin/scan_private_network`, `bin/scan_target_network`, `bin/scan_devices`, `bin/system/network_topology_scan.sh`, `bin/network_topology_scan.sh`。新入口為 `bin/network/scan_network.sh`。

## 加入流程 (Add New Tool)

1. 決定 area: `bash` / `mac` / `system` / `vscode` / `network`
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

使用範例 (`bin/mac/disk_analysis-mac.sh`):
```bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_lib_audit.sh"
audit_init "disk_analysis"
header "1. 整體磁碟空間概覽"
log "主磁碟: ${TOTAL}GB"
```

## 排程 (Scheduling)

`ecosystem.config.js` 之 `Local` namespace 統一管理本機排程;
所有 task 必須以 `./bin/<area>/<tool>` 全路徑註冊, 不接受相對名稱呼叫, 避免 pm2 切換工作目錄後找不到入口。
