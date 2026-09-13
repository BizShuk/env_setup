# Docker Container Test Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立自動化的 Docker 容器套件安裝與指令測試腳本，支援自動清理容器並整合至 npm 任務清單。

**Architecture:** 撰寫 `scripts/test_docker_install.sh`，透過 Docker CLI 啟動隔離的 Ubuntu 容器，並利用 shell `trap` 機制確保無論測試成功、失敗或收到中斷訊號時，容器均被自動完全銷毀。於容器內依序安裝核心開發工具鏈（Go、Node.js、Git、Vim）、建置 `env_setup` CLI，並對所有安裝後指令進行非空與正常運作斷言。透過 `package.json` 的 `npm run test:docker` 整合對外呼叫介面。

**Tech Stack:** Bash, Docker (Ubuntu 24.04/22.04), Node.js (package.json npm script), Go 1.26.

## Global Constraints

- 單一檔案單一職責：Docker 測試邏輯封裝於 `scripts/test_docker_install.sh`。
- 容器生命週期保證：必須使用 `trap '...' EXIT INT TERM` 確保容器銷毀。
- 統一任務介面：以 `package.json` 為唯一任務清單，新增 `npm run test:docker`。
- 高階繁體中文輸出與 English Terminology。

---

### Task 1: 建立 Docker 容器測試腳本 (Docker Container Test Runner)

**Files:**
- Create: `scripts/test_docker_install.sh`

**Interfaces:**
- Consumes: 本機 Docker CLI、`scripts/go.sh`、`scripts/nodejs.sh`、`scripts/git.sh`、`scripts/vim.sh`。
- Produces: 獨立執行檔 `scripts/test_docker_install.sh`，可直接執行或透過 npm 呼叫。

- [ ] **Step 1: 編寫 `scripts/test_docker_install.sh`**

建立腳本，包含：
1. 嚴格 shell 模式：`set -euo pipefail`。
2. Docker daemon 連線偵測與友善提示。
3. 產生具備隨機種子之容器名稱（如 `env_setup_test_$(date +%s)_$$`）。
4. 註冊 `trap cleanup EXIT INT TERM`，函式內呼叫 `docker rm -f "${CONTAINER_NAME}"`。
5. 啟動 `ubuntu:24.04` 容器掛載當前 repo 目錄至 `/workspace`。
6. 於容器內部執行：
   - 更新 apt 並安裝必備工具：`sudo apt-get update && sudo apt-get install -y --no-install-recommends ca-certificates curl sudo tar build-essential`
   - 建立非 root 測試帳號或以預設環境執行工具鏈安裝
   - 執行 `./scripts/go.sh`、`./scripts/nodejs.sh`、`./scripts/git.sh`、`./scripts/vim.sh`
   - 建置 CLI：`go build -o tmp/env_setup .`
   - 斷言測試指令：`go version`、`node -v`、`npm -v`、`git --version`、`vim --version`、`./tmp/env_setup system os show`、`./tmp/env_setup system cpu show`
7. 輸出驗證成功訊息。

- [ ] **Step 2: 賦予執行權限並驗證 Shell 語法**

執行語法檢查：
```bash
bash -n scripts/test_docker_install.sh
chmod +x scripts/test_docker_install.sh
```
預期輸出：語法無任何錯誤。

- [ ] **Step 3: 驗證 Daemon 未啟動時之退出與清理防護**

在未啟動 Docker 或指定無效 socket 情況下執行：
```bash
DOCKER_HOST=unix:///nonexistent.sock ./scripts/test_docker_install.sh || echo "Exit code: $?"
```
預期輸出：輸出友善的 Docker 未連線提示並正常非零退出。

- [ ] **Step 4: 提交腳本變更至 Git**

```bash
git add scripts/test_docker_install.sh
git commit -m "feat(scripts): add docker container test runner with auto cleanup"
```

---

### Task 2: 整合 npm 任務清單與專案文件 (NPM Script & Docs Integration)

**Files:**
- Modify: `package.json`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `scripts/test_docker_install.sh`
- Produces: `npm run test:docker` 任務指令

- [ ] **Step 1: 在 `package.json` 新增 `test:docker` 指令**

在 `package.json` 的 `"scripts"` 中新增：
```json
"test:docker": "bash scripts/test_docker_install.sh"
```

- [ ] **Step 2: 驗證 `package.json` 語法**

執行：
```bash
npm run test:docker --dry-run || node -e "JSON.parse(require('fs').readFileSync('package.json'))"
```
預期輸出：JSON 格式正確。

- [ ] **Step 3: 更新 `CLAUDE.md` 任務清單與說明**

於 `CLAUDE.md` 測試或任務說明段落中，補充 `npm run test:docker` 作為 Ubuntu 隔離安裝與指令測試方法。

- [ ] **Step 4: 提交整合變更至 Git**

```bash
git add package.json CLAUDE.md
git commit -m "feat(task): integrate test:docker npm script and update docs"
```

---

### Task 3: 驗證與完工檢查 (Verification & Completion)

**Files:**
- None (驗證現有產出)

- [ ] **Step 1: 執行既有 CI 驗證**

執行既有整合檢查確保未破壞既有程式庫與風格：
```bash
npm run lint
npm run test
npm run build
```
預期輸出：既有 Go lint, unit test, bash plugin test, build 全部 PASS。

- [ ] **Step 2: 終端總結與使用者報告**

依據高階繁體中文規則彙整功能與差異，回報實作完成。
