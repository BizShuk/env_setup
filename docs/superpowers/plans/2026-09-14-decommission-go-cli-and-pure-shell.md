# Decommission Go CLI and Transition to Pure Shell Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 廢除 Go CLI 相關程式碼與依賴，轉型為純 Shell 腳本工具箱；移除 GitHub Actions；於 PM2 (`ecosystem.config.js`) 擴充所有非安裝類檢測任務；重構 `package.json` 生命週期並更新專案文件。

**Architecture:** 徹底刪除 `cmd/`, `svc/`, `model/`, `main.go`, `go.mod`, `go.sum` 與 `.github/`。將 `package.json` 的 `lint`, `test`, `ci`, `clean` 轉為純 Shell 治理（明確保留 `tmp/` 軟連結）。於 `ecosystem.config.js` 註冊全套非安裝類系統檢測、硬體探測、安全稽核與備份狀態任務。同步更新 `CLAUDE.md` 與 `README.md`。

**Tech Stack:** Bash/Shell, Node.js (package.json npm scripts), PM2.

## Global Constraints

- 一檔一責、一包一領域：保留既有 `scripts/<domain>/` 架構。
- 軟連結防護：`clean` 任務僅清除日誌與臨時廢棄檔，嚴格保留 `tmp/` 目錄與其承載之符號連結。
- 語法檢查覆蓋：`npm run lint` 必須檢查 `scripts` 與 `bin` 下所有 `.sh` 腳本之語法。
- 高階輸出：繁體中文與 English Terminology。

---

### Task 1: 刪除 Go 原始碼與 Module 依賴檔

**Files:**
- Delete: `cmd/`
- Delete: `svc/`
- Delete: `model/`
- Delete: `main.go`
- Delete: `go.mod`
- Delete: `go.sum`

- [ ] **Step 1: 執行 Git 刪除**
  `git rm -r cmd svc model main.go go.mod go.sum`
- [ ] **Step 2: 驗證無殘留 Go 原始碼**
  `find . -maxdepth 2 -name "*.go"`（確認僅非 source 檔案或為空）
- [ ] **Step 3: 提交 Commit**
  `git commit -m "chore: decommission go cli and remove go source files"`

---

### Task 2: 移除 GitHub Actions

**Files:**
- Delete: `.github/workflows/ci.yml`
- Delete: `.github/`

- [ ] **Step 1: 執行 Git 刪除**
  `git rm -r .github/`
- [ ] **Step 2: 提交 Commit**
  `git commit -m "chore: remove github actions workflows"`

---

### Task 3: 重構 `package.json` 生命週期指令

**Files:**
- Modify: `package.json`

- [ ] **Step 1: 更新 package.json 描述與生命週期任務**
  - 更新 `description`，移除 Go CLI 敘述。
  - 移除 `dev`, `build`, `deploy`, `vuln`, `destroy` 指令。
  - 更新 `lint` 為: `find scripts bin -type f -name "*.sh" -exec bash -n {} +`
  - 更新 `test` 為: `bash scripts/test_bash_plugin.sh`
  - 更新 `clean` 為: `rm -f *.log **/*.log .*.tmp.* .*.err.*`
  - 更新 `ci` 為: `npm run lint && npm run test`
- [ ] **Step 2: 驗證 package.json 語法**
  `node -e "require('./package.json')"`
- [ ] **Step 3: 驗證 npm run lint 與 npm test**
  執行 `npm run lint && npm test`
- [ ] **Step 4: 提交 Commit**
  `git add package.json && git commit -m "feat(task): refactor package.json lifecycle for pure shell"`

---

### Task 4: 擴充 PM2 非安裝類檢測排程 (`ecosystem.config.js`)

**Files:**
- Modify: `ecosystem.config.js`

- [ ] **Step 1: 更新 ecosystem.config.js 任務清單**
  註冊全套非安裝類檢測與稽核排程：
  - `Disk Cleanup Preview`: `./scripts/cleanup/all.sh` (cron: `0 5 * * 5`)
  - `Launch Audit`: `./bin/mac/launch_audit-mac.sh` (cron: `0 5 * * 5`)
  - `Login Audit`: `./bin/mac/login_audit-mac.sh` (cron: `0 5 * * 5`)
  - `Network Security Audit`: `./bin/mac/network_security_audit-mac.sh` (cron: `0 5 * * 5`)
  - `System Health Probe`: `./scripts/system/show.sh` (cron: `0 6 * * 1`)
  - `Storage Device Probe`: `./scripts/io/probe.sh` (cron: `0 6 * * 1`)
  - `Backup Status Audit`: `./scripts/backup/list.sh` (cron: `0 7 * * 1`)
  - `Private Route Topology`: `./scripts/network/private.sh` (cron: `0 8 * * 1`)
  - 移除相依 Go 的 `Golang Clean Cache` 與 `Golang Clean ModCache`。
- [ ] **Step 2: 驗證 ecosystem.config.js 語法與導出**
  `node -e "const c = require('./ecosystem.config.js'); console.log(c.apps.map(a => a.name))"`
- [ ] **Step 3: 提交 Commit**
  `git add ecosystem.config.js && git commit -m "feat(pm2): add all non-install inspection and probe tasks"`

---

### Task 5: 更新專案技術與業務文件 (`CLAUDE.md`, `README.md`)

**Files:**
- Modify: `CLAUDE.md`
- Modify: `README.md`
- Modify: `docs/bin_index.md`

- [ ] **Step 1: 更新 `CLAUDE.md`**
  - 專案結構樹移除 Go 原始碼、`.github/`，強調 `scripts/<domain>/`。
  - 技術棧更新為 Bash/Shell、Node.js / npm scripts、PM2。
  - 模組對應表將所有進入點統一指向 `scripts/<domain>/` 與 `npm run run:<domain>:*`。
  - 關鍵決策移除 Go CLI、Cobra、gosdk、GitHub Actions 等段落，強調純腳本與 PM2 檢測。
- [ ] **Step 2: 更新 `README.md`**
  - 更新首段簡介，確立為純 Shell + npm 工具箱 repo。
  - 8 大領域章節移除 Go CLI 進入點，全面以 `npm run run:<domain>:*` 與 `scripts/<domain>/` 為準。
- [ ] **Step 3: 更新 `docs/bin_index.md`**
  - 更新 Domain Utilities 章節，移除 `env_setup <cmd>` 參照，改為指向 `scripts/<domain>/`。
- [ ] **Step 4: 提交 Commit**
  `git add CLAUDE.md README.md docs/bin_index.md && git commit -m "docs: align architecture and domain guides with pure shell structure"`

---

### Task 6: 全專案整合回歸驗證

- [ ] **Step 1: 執行 npm run ci**
  `npm run ci`
- [ ] **Step 2: 執行 clean 任務並驗證 tmp/ 軟連結完整性**
  `npm run clean && test -d tmp && echo "tmp preserved"`
- [ ] **Step 3: 驗證 git status 乾淨無未追蹤檔案**
  `git status`
