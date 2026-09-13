# Pure Scripts Modularization Design

## 目標

將 `@cmd/` 與 `@svc/` 現有的 8 大核心領域（Dump、Install、Backup、Cleanup、System、Network、Uninstall、IO）轉換並建立為 `@scripts/` 下的純 Shell 腳本體系，遵循「一檔一責、一包一領域 (One File One Responsibility, One Package/Folder One Domain)」架構，並於 `package.json` 註冊對應的 `run:<domain>:<action>` 指令。

## 架構與目錄結構

保持既有環境安裝腳本在 `scripts/` 根目錄不變，新增以下領域子目錄與獨立腳本：

```text
scripts/
├── dump/
│   ├── mac.sh                 # 匯出 Homebrew/Cask/MAS 清單至 scripts/Brewfile
│   ├── vscode.sh              # 匯出 VS Code 擴充套件清單至 bin/vscode/vscode_extension_list.txt
│   └── antigravity.sh         # 匯出 Antigravity 擴充套件清單至 bin/vscode/agy-ide_extension_list.txt
├── install/
│   ├── vscode.sh              # 依據 Manifest 批次安裝/同步 VS Code 擴充套件
│   └── antigravity.sh         # 依據 Manifest 批次安裝/同步 Antigravity 擴充套件
├── backup/
│   ├── backup.sh              # 匯出追蹤之 macOS Defaults 至 .plist 快照與中繼資料
│   ├── list.sh                # 檢視備份快照時間與追蹤 Domain 狀態清單
│   ├── import.sh              # 還原 Defaults 快照並支援 Diff 檢視與確認機制
│   └── init.sh                # 建立預設的 Domain 追蹤 Manifest 設定
├── cleanup/
│   ├── all.sh                 # 聚合執行各清理元件（支援 --preview 與 --apply）
│   ├── system_log.sh          # 系統層日誌清理 (/private/var/log, /Library/Logs)
│   ├── system_tmp.sh          # 系統層暫存清理 (/private/var/tmp)
│   ├── cache_user.sh          # 使用者層快取清理 (~/.cache, ~/Library/Caches, ~/.Trash)
│   ├── docker.sh              # Docker 未使用之 containers, images, builder cache 清理
│   ├── brew.sh                # Homebrew cache 與未宣告套件清理
│   ├── node.sh                # npm, npx, bun cache 與專案 node_modules 清理
│   ├── python.sh              # pip, uv cache 與虛擬環境目錄 (*venv*) 清理
│   ├── go.sh                  # Go build cache 與 workspace cache 清理
│   ├── ai.sh                  # Claude, Codex, Gemini 舊 session 與暫存檔清理
│   ├── browser.sh             # Chrome, Safari cache 與暫存清理
│   └── app.sh                 # Lark 通訊軟體、iOS 備份、Podcasts 等應用程式暫存清理
├── system/
│   ├── show.sh                # 聚合顯示全系統與硬體資訊
│   ├── cpu.sh                 # 查詢 CPU 型號、架構與核心資訊
│   ├── memory.sh              # 查詢記憶體大小與通道規格
│   ├── disk.sh                # 查詢磁碟分割區與掛載資訊
│   ├── network.sh             # 查詢本機網路介面與 IP 配置
│   ├── os.sh                  # 查詢作業系統版本與核心版本
│   ├── gpu.sh                 # 查詢顯示卡資訊
│   ├── display.sh             # 查詢顯示器解析度與介面
│   ├── usb.sh                 # 查詢 USB 控制器與外接裝置
│   ├── input.sh               # 查詢鍵盤、滑鼠、觸控板等輸入裝置
│   ├── audio.sh               # 查詢音訊輸入輸出裝置
│   └── disk_verify.sh         # 驗證外接儲存媒體健康度與真實容量 (F3)
├── network/
│   ├── private.sh             # 路由追蹤私有 IP 節點拓撲 (Traceroute)
│   └── target.sh              # 掃描目標 CIDR 網段活躍主機與服務 (Nmap/Ping)
├── uninstall/
│   └── codex.sh               # 預覽與清理 Codex 應用程式、CLI 與使用者設定 (--apply)
└── io/
    ├── probe.sh               # 探測實體儲存裝置傳輸介面、驅動與佇列深度
    └── bench.sh               # 略過 Page Cache 進行磁碟循序寫入與隨機讀寫評測
```

## 各領域職責與行為規格

1. **Dump (`scripts/dump/`)**:
   - `mac.sh`: 驗證 `brew` 存在，執行 `brew bundle dump --force --file=<repo>/scripts/Brewfile`。
   - `vscode.sh`: 呼叫 `code --list-extensions`，輸出排序並去重，原子替換寫入 `bin/vscode/vscode_extension_list.txt`。
   - `antigravity.sh`: 解析 Antigravity extensions 目錄，呼叫 `antigravity --list-extensions`，排序去重寫入 `bin/vscode/agy-ide_extension_list.txt`。

2. **Install (`scripts/install/`)**:
   - `vscode.sh`: 讀取 `bin/vscode/vscode_extension_list.txt`，逐行執行 `code --install-extension <ext> --force`。
   - `antigravity.sh`: 讀取 `bin/vscode/agy-ide_extension_list.txt`，逐行執行 `antigravity --install-extension <ext> --force`。

3. **Backup (`scripts/backup/`)**:
   - `init.sh`: 初始化 `~/.config/env_setup/mac_backup_domains.json`（若不存在從預設範本複製）。
   - `backup.sh`: 讀取已追蹤的 domain 清單，使用 `defaults export <domain>` 或 `plutil` 匯出至 `~/.config/env_setup/backup/<domain>.plist`，並更新 `backup.meta.json`。
   - `list.sh`: 讀取 `backup.meta.json` 顯示備份時間戳記，並列出每個 domain 狀態。
   - `import.sh`: 預覽或還原備份，支援 `--yes` 略過確認與 diff 檢視。

4. **Cleanup (`scripts/cleanup/`)**:
   - 包含 `system_log.sh`, `system_tmp.sh`, `cache_user.sh`, `docker.sh`, `brew.sh`, `node.sh`, `python.sh`, `go.sh`, `ai.sh`, `browser.sh`, `app.sh` 及聚合入口 `all.sh`。
   - 預設行為均為預覽 (Preview / Dry-Run)，輸出欲刪除之路徑與估算空間。
   - 只有帶入 `--apply` 時，提示確認 `[y/N]` 後才執行實際清除。

5. **System (`scripts/system/`)**:
   - `show.sh`: 依序呼叫各硬體與系統資訊子腳本，印出摘要報告。
   - `cpu.sh`, `memory.sh`, `disk.sh`, `network.sh`, `os.sh`, `gpu.sh`, `display.sh`, `usb.sh`, `input.sh`, `audio.sh`: 依 `uname` 分流原生系統指令（macOS: `system_profiler`, `sysctl`, `diskutil`；Linux: `lshw`, `lsblk`, `/proc`）。
   - `disk_verify.sh`: 接受掛載路徑參數，使用 `f3write` / `f3read` 進行隨身碟與外接碟真偽與壞軌驗證。

6. **Network (`scripts/network/`)**:
   - `private.sh`: 接受目標 IP/Host（預設 `1.1.1.1` 或 `8.8.8.8`），以 `traceroute` 追蹤並過濾出私有 IP 網段路由節點。
   - `target.sh`: 接受 CIDR（預設為本機網段），若有 `nmap` 則執行 `nmap -sn`，否則以 Ping sweep 偵測上線設備。

7. **Uninstall (`scripts/uninstall/`)**:
   - `codex.sh`: 預設掃描並列出 Codex App (`/Applications/Codex.app`)、CLI (`~/.local/bin/codex`)、設定檔 (`~/.codex`) 與 Launchd agents；帶 `--apply` 經確認後清理。

8. **IO (`scripts/io/`)**:
   - `probe.sh`: 呼叫 `diskutil list` / `diskutil info` (macOS) 或 `lsblk` (Linux)，探測實體磁碟與控制器資訊。
   - `bench.sh`: 在指定目錄或暫存區建立測試檔，以 `dd` (含 `sync` / `direct`) 測試寫入/讀取速度後清除測試檔。

## Package.json 指令整合

於 `package.json` 的 `scripts` 區塊註冊對應的 `run:<domain>:<action>` 入口：

- `run:dump:mac`, `run:dump:vscode`, `run:dump:antigravity`
- `run:install:vscode`, `run:install:antigravity`
- `run:backup`, `run:backup:list`, `run:backup:import`, `run:backup:init`
- `run:cleanup`, `run:cleanup:system-log`, `run:cleanup:system-tmp`, `run:cleanup:cache-user`, `run:cleanup:docker`, `run:cleanup:brew`, `run:cleanup:node`, `run:cleanup:python`, `run:cleanup:go`, `run:cleanup:ai`, `run:cleanup:browser`, `run:cleanup:app`
- `run:system:show`, `run:system:cpu`, `run:system:memory`, `run:system:disk`, `run:system:network`, `run:system:os`, `run:system:gpu`, `run:system:display`, `run:system:usb`, `run:system:input`, `run:system:audio`, `run:system:disk-verify`
- `run:network:private`, `run:network:target`
- `run:uninstall:codex`
- `run:io:probe`, `run:io:bench`

## 驗證計畫

1. **語法完整性**：執行 `bash -n` 驗證所有新增之 shell scripts。
2. **乾跑測試**：
   - 執行 `npm run run:system:show` 確認系統狀態資訊正確輸出。
   - 執行 `npm run run:cleanup` 確認預覽模式正確列出項目且不具破壞性。
   - 執行 `npm run run:backup:list` 確認備份清單運作。
3. **既有測試回歸**：執行 `npm test` 確認既有專案測試全數通過。
