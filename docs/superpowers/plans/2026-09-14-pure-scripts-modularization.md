# Pure Scripts Modularization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 將 `@cmd/` 與 `@svc/` 現有的 8 大領域核心功能以純 Bash 腳本實作並依 Domain 建立於 `@scripts/` 下，遵循「一檔一責、一包一領域」原則，並於 `package.json` 整合註冊對應的 `run:<domain>:<action>` 指令。

**Architecture:** 保持既有安裝腳本不變，新增 `scripts/dump/`, `scripts/install/`, `scripts/backup/`, `scripts/cleanup/`, `scripts/system/`, `scripts/network/`, `scripts/uninstall/`, `scripts/io/` 8 個領域目錄。各腳本透過 `source bin/bash/settings.sh` 載入基礎路徑，對破壞性操作（如 cleanup, uninstall, backup import）預設實施乾跑預覽 (Preview Mode) 並要求 `--apply` 參數與使用者互動確認。於 `package.json` 的 `scripts` 註冊全套 `run:<domain>:<action>` 指令。

**Tech Stack:** Bash (macOS & Linux), Node.js (package.json npm scripts), macOS tools (`defaults`, `plutil`, `system_profiler`, `diskutil`, `f3`), Linux tools (`lsblk`, `/proc`).

## Global Constraints

- 一檔一責：每個動作獨立腳本，不以大型 Facade 腳本混合多重邏輯。
- 一包一領域：每個資料夾對應單一業務領域。
- 破壞性操作預設乾跑 (Safe by Default)：`cleanup/*`, `uninstall/codex.sh`, `backup/import.sh` 預設僅列出目標與預估容量，帶入 `--apply` 才執行確認與刪除。
- 語法保證：所有新腳本必須通過 `bash -n` 語法檢查並具備執行權限 (`chmod +x`)。
- 繁體中文與 English Terminology 保持高階輸出。

---

### Task 1: 建立 Manifest Dump 腳本 (Dump Domain)

**Files:**
- Create: `scripts/dump/mac.sh`
- Create: `scripts/dump/vscode.sh`
- Create: `scripts/dump/antigravity.sh`

**Interfaces:**
- Consumes: `brew bundle dump`, `code --list-extensions`, `antigravity --list-extensions`
- Produces: `scripts/Brewfile`, `bin/vscode/vscode_extension_list.txt`, `bin/vscode/agy-ide_extension_list.txt`

- [ ] **Step 1: 實作 `scripts/dump/mac.sh`**
  驗證 macOS 與 `brew` 命令，呼叫 `brew bundle dump --force --file="${REPO_DIR}/scripts/Brewfile"`。
- [ ] **Step 2: 實作 `scripts/dump/vscode.sh`**
  驗證 `code` 命令，執行 `code --list-extensions`，經 `sort -u` 排序去重後寫入 `${REPO_DIR}/bin/vscode/vscode_extension_list.txt`。
- [ ] **Step 3: 實作 `scripts/dump/antigravity.sh`**
  驗證 `antigravity` 命令，解析 extensions 目錄，執行 `antigravity --list-extensions` 排序去重後寫入 `${REPO_DIR}/bin/vscode/agy-ide_extension_list.txt`。
- [ ] **Step 4: 賦予執行權限並驗證語法**
  執行 `bash -n scripts/dump/*.sh && chmod +x scripts/dump/*.sh`。
- [ ] **Step 5: 提交 Commit**
  `git add scripts/dump/ && git commit -m "feat(scripts): add dump domain pure scripts"`

---

### Task 2: 建立 Extension Install 腳本 (Install Domain)

**Files:**
- Create: `scripts/install/vscode.sh`
- Create: `scripts/install/antigravity.sh`

**Interfaces:**
- Consumes: `bin/vscode/vscode_extension_list.txt`, `bin/vscode/agy-ide_extension_list.txt`
- Produces: 依據 Manifest 批次執行 `code --install-extension` 與 `antigravity --install-extension`

- [ ] **Step 1: 實作 `scripts/install/vscode.sh`**
  檢查 Manifest 檔案是否存在，逐行讀取非空 extension ID 並執行 `code --install-extension "${ext}" --force`。
- [ ] **Step 2: 實作 `scripts/install/antigravity.sh`**
  檢查 Manifest 檔案是否存在，逐行讀取非空 extension ID 並執行 `antigravity --install-extension "${ext}" --force`。
- [ ] **Step 3: 賦予執行權限並驗證語法**
  執行 `bash -n scripts/install/*.sh && chmod +x scripts/install/*.sh`。
- [ ] **Step 4: 提交 Commit**
  `git add scripts/install/ && git commit -m "feat(scripts): add install domain pure scripts"`

---

### Task 3: 建立 macOS Defaults Backup 腳本 (Backup Domain)

**Files:**
- Create: `scripts/backup/init.sh`
- Create: `scripts/backup/backup.sh`
- Create: `scripts/backup/list.sh`
- Create: `scripts/backup/import.sh`

**Interfaces:**
- Consumes: macOS `defaults`, `plutil`, `~/.config/env_setup/mac_backup_domains.json`
- Produces: `~/.config/env_setup/backup/*.plist`, `~/.config/env_setup/backup/backup.meta.json`

- [ ] **Step 1: 實作 `scripts/backup/init.sh`**
  檢查若 `~/.config/env_setup/mac_backup_domains.json` 不存在，則以預設追蹤 domain 清單初始化該檔案。
- [ ] **Step 2: 實作 `scripts/backup/backup.sh`**
  讀取 tracked domains，逐一匯出 `defaults export <domain> <dest>.plist`，並寫入快照時間至 `backup.meta.json`。
- [ ] **Step 3: 實作 `scripts/backup/list.sh`**
  讀取 `backup.meta.json` 輸出最近備份時間與每個 domain 的 plist 狀態。
- [ ] **Step 4: 實作 `scripts/backup/import.sh`**
  檢查備份目錄，支援 `--diff` 比對目前設定與快照差異，帶 `--apply` 經確認後透過 `defaults import` 還原。
- [ ] **Step 5: 賦予執行權限並驗證語法**
  執行 `bash -n scripts/backup/*.sh && chmod +x scripts/backup/*.sh`。
- [ ] **Step 6: 提交 Commit**
  `git add scripts/backup/ && git commit -m "feat(scripts): add backup domain pure scripts"`

---

### Task 4: 建立 Cleanup 子元件腳本 (Cleanup Domain)

**Files:**
- Create: `scripts/cleanup/system_log.sh`
- Create: `scripts/cleanup/system_tmp.sh`
- Create: `scripts/cleanup/cache_user.sh`
- Create: `scripts/cleanup/docker.sh`
- Create: `scripts/cleanup/brew.sh`
- Create: `scripts/cleanup/node.sh`
- Create: `scripts/cleanup/python.sh`
- Create: `scripts/cleanup/go.sh`
- Create: `scripts/cleanup/ai.sh`
- Create: `scripts/cleanup/browser.sh`
- Create: `scripts/cleanup/app.sh`
- Create: `scripts/cleanup/all.sh`

**Interfaces:**
- Consumes: 各應用程式與系統路徑
- Produces: 預設輸出待刪除路徑與估算大小；`--apply` 經確認後安全刪除

- [ ] **Step 1: 實作 `scripts/cleanup/system_log.sh` 與 `system_tmp.sh`**
  掃描 `/private/var/log`, `/Library/Logs` 與 `/private/var/tmp`。
- [ ] **Step 2: 實作 `scripts/cleanup/cache_user.sh`**
  掃描 `~/.cache`, `~/Library/Caches`, `~/.Trash`。
- [ ] **Step 3: 實作開發工具清理腳本 (`docker.sh`, `brew.sh`, `node.sh`, `python.sh`, `go.sh`)**
  分別支援 Docker prune、Homebrew cache/bundle cleanup、npm/bun cache & node_modules、pip/uv/venv 清理、go clean -cache。
- [ ] **Step 4: 實作應用程式清理腳本 (`ai.sh`, `browser.sh`, `app.sh`)**
  支援 Claude/Codex/Gemini 舊 sessions 清理、Chrome/Safari 暫存清理、Lark/Podcasts/iOS 備份清理。
- [ ] **Step 5: 實作聚合入口 `scripts/cleanup/all.sh`**
  依序呼叫上述子腳本，透傳 `--apply` 參數。
- [ ] **Step 6: 賦予執行權限並驗證語法**
  執行 `bash -n scripts/cleanup/*.sh && chmod +x scripts/cleanup/*.sh`。
- [ ] **Step 7: 提交 Commit**
  `git add scripts/cleanup/ && git commit -m "feat(scripts): add cleanup domain subcomponent pure scripts"`

---

### Task 5: 建立 System 資訊探測腳本 (System Domain)

**Files:**
- Create: `scripts/system/show.sh`
- Create: `scripts/system/cpu.sh`
- Create: `scripts/system/memory.sh`
- Create: `scripts/system/disk.sh`
- Create: `scripts/system/network.sh`
- Create: `scripts/system/os.sh`
- Create: `scripts/system/gpu.sh`
- Create: `scripts/system/display.sh`
- Create: `scripts/system/usb.sh`
- Create: `scripts/system/input.sh`
- Create: `scripts/system/audio.sh`
- Create: `scripts/system/disk_verify.sh`

**Interfaces:**
- Consumes: macOS (`system_profiler`, `sysctl`, `diskutil`, `f3write`, `f3read`), Linux (`/proc`, `lshw`, `lsblk`)
- Produces: 終端機格式化硬體與系統狀態表格

- [ ] **Step 1: 實作各硬體與系統資訊子腳本 (`cpu.sh` ~ `audio.sh`, `os.sh`)**
  依 `uname` 偵測系統並執行對應原生指令，輸出簡潔資訊。
- [ ] **Step 2: 實作 `scripts/system/disk_verify.sh`**
  接收掛載路徑參數，檢查 `f3write`/`f3read`，驗證隨身碟容量真偽。
- [ ] **Step 3: 實作 `scripts/system/show.sh`**
  聚合呼叫所有子項目，呈現全系統硬體概況報告。
- [ ] **Step 4: 賦予執行權限並驗證語法**
  執行 `bash -n scripts/system/*.sh && chmod +x scripts/system/*.sh`。
- [ ] **Step 5: 提交 Commit**
  `git add scripts/system/ && git commit -m "feat(scripts): add system domain pure scripts"`

---

### Task 6: 建立 Network 拓撲與掃描腳本 (Network Domain)

**Files:**
- Create: `scripts/network/private.sh`
- Create: `scripts/network/target.sh`

**Interfaces:**
- Consumes: `traceroute`, `nmap`, `ping`
- Produces: 私有跳點路由拓撲、目標網段活躍主機清單

- [ ] **Step 1: 實作 `scripts/network/private.sh`**
  使用 `traceroute` 追蹤目標位址，並篩選出 RFC 1918 私有 IP 跳點 (`10.*`, `172.16-31.*`, `192.168.*`)。
- [ ] **Step 2: 實作 `scripts/network/target.sh`**
  接受 CIDR 參數（預設依本機網段），若有 `nmap` 跑 `nmap -sn`，否則以 Ping sweep 偵測上線設備。
- [ ] **Step 3: 賦予執行權限並驗證語法**
  執行 `bash -n scripts/network/*.sh && chmod +x scripts/network/*.sh`。
- [ ] **Step 4: 提交 Commit**
  `git add scripts/network/ && git commit -m "feat(scripts): add network domain pure scripts"`

---

### Task 7: 建立 Codex Uninstall 腳本 (Uninstall Domain)

**Files:**
- Create: `scripts/uninstall/codex.sh`

**Interfaces:**
- Consumes: `/Applications/Codex.app`, `~/.local/bin/codex`, `~/.codex`, `~/Library/LaunchAgents/com.codex.*`
- Produces: 預設預覽待刪除 Codex 元件；`--apply` 經確認後停止程序並清除檔案

- [ ] **Step 1: 實作 `scripts/uninstall/codex.sh`**
  掃描 Codex 應用程式、CLI、Launchd 與使用者資料；支援 `--apply` 與 `[y/N]` 確認防護。
- [ ] **Step 2: 賦予執行權限並驗證語法**
  執行 `bash -n scripts/uninstall/codex.sh && chmod +x scripts/uninstall/codex.sh`。
- [ ] **Step 3: 提交 Commit**
  `git add scripts/uninstall/ && git commit -m "feat(scripts): add uninstall domain codex pure script"`

---

### Task 8: 建立 IO 探測與評測腳本 (IO Domain)

**Files:**
- Create: `scripts/io/probe.sh`
- Create: `scripts/io/bench.sh`

**Interfaces:**
- Consumes: macOS `diskutil`, Linux `lsblk`, `dd`
- Produces: 磁碟控制器/傳輸介面表格，循序寫入與隨機讀寫 IOPS/MBps 報告

- [ ] **Step 1: 實作 `scripts/io/probe.sh`**
  依 platform 輸出磁碟清單、容量、傳輸介面 (SATA/NVMe/USB)。
- [ ] **Step 2: 實作 `scripts/io/bench.sh`**
  在指定或暫存目錄建立測試檔，以 `dd` 測試寫入/讀取效能後自動清理測試檔。
- [ ] **Step 3: 賦予執行權限並驗證語法**
  執行 `bash -n scripts/io/*.sh && chmod +x scripts/io/*.sh`。
- [ ] **Step 4: 提交 Commit**
  `git add scripts/io/ && git commit -m "feat(scripts): add io domain pure scripts"`

---

### Task 9: 整合 `package.json` 指令與全域語法驗證

**Files:**
- Modify: `package.json`

- [ ] **Step 1: 於 `package.json` 註冊全套 `run:<domain>:<action>` 指令**
  加入 dump, install, backup, cleanup, system, network, uninstall, io 全套指令。
- [ ] **Step 2: 執行所有 Shell 腳本的語法檢查**
  執行 `bash -n scripts/**/*.sh` 確認所有腳本語法正確。
- [ ] **Step 3: 執行安全指令驗證**
  執行 `npm run run:system:show`, `npm run run:cleanup`, `npm run run:backup:list` 驗證輸出。
- [ ] **Step 4: 執行既有測試套件**
  執行 `npm test` 確認既有 Go tests 與 shell plugin tests 均通過。
- [ ] **Step 5: 提交 Commit**
  `git add package.json && git commit -m "feat(task): register pure scripts commands in package.json"`

---

### Task 10: 更新專案技術與業務文件

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`

- [ ] **Step 1: 更新 `CLAUDE.md` 專案結構與模組對應**
  在目錄樹與模組映射表中補上 `scripts/<domain>/` 與對應純腳本清單。
- [ ] **Step 2: 更新 `README.md` 領域流程**
  將純腳本呼叫入口補充至相關領域章節。
- [ ] **Step 3: 提交 Commit**
  `git add CLAUDE.md README.md && git commit -m "docs: update project structure and domains for pure scripts"`
