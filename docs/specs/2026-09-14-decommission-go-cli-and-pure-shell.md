# Decommission Go CLI and Transition to Pure Shell Architecture Design

## 目標

將 `env_setup` 專案徹底廢除 Go CLI 相關實作與依賴，轉型為純 Shell 腳本搭配 `package.json` 任務管理工具箱；移除 GitHub Actions 自動化工作流；於 PM2 (`ecosystem.config.js`) 補齊全套非安裝類系統檢測、硬體探測、安全稽核與備份狀態任務。

## 變更範圍 (Scope of Changes)

### 1. 廢除與刪除 Go 程式碼
徹底移除下列目錄與檔案：
- `cmd/`：Cobra CLI 命令模組
- `svc/`：Go 業務服務實作與測試
- `model/`：資料模型目錄
- `main.go`：CLI 進入點
- `go.mod`、`go.sum`：Go Module 依賴檔

### 2. 移除 GitHub Actions
- 刪除 `.github/workflows/ci.yml` 與 `.github/` 目錄。

### 3. 重構 `package.json` 生命週期指令
- 移除 Go 專屬指令：`dev`, `build`, `deploy`, `vuln`, `destroy`。
- `lint`：執行 Shell 語法檢查（`find scripts bin -type f -name "*.sh" -exec bash -n {} +`）。
- `test`：執行 Shell 插件測試 (`bash scripts/test_bash_plugin.sh`)。
- `test:docker`：保留 Docker 容器測試（預設 `ubuntu:26.04`，支援 `DOCKER_TEST_IMAGE` 覆寫）。
- `clean`：專注清理專案多餘日誌與臨時檔案（`rm -f *.log **/*.log .*.tmp.* .*.err.*`），**嚴格保留 `tmp/` 目錄與其承載之系統/使用者軟連結**。
- `ci`：標準化為 `npm run lint && npm run test`。
- 完整保留 38 個 `run:<domain>:<action>` 領域純腳本指令。

### 4. 擴充 PM2 非安裝類檢測排程 (`ecosystem.config.js`)
註冊所有週期性唯讀探測、安全稽核與快照狀態檢驗任務：
1. `Disk Cleanup Preview` (`./scripts/cleanup/all.sh`)：每週五 05:00 預覽
2. `Launch Audit` (`./bin/mac/launch_audit-mac.sh`)：每週五 05:00 稽核
3. `Login Audit` (`./bin/mac/login_audit-mac.sh`)：每週五 05:00 稽核
4. `Network Security Audit` (`./bin/mac/network_security_audit-mac.sh`)：每週五 05:00 稽核
5. `System Health Probe` (`./scripts/system/show.sh`)：每週一 06:00 探測
6. `Storage Device Probe` (`./scripts/io/probe.sh`)：每週一 06:00 探測
7. `Backup Status Audit` (`./scripts/backup/list.sh`)：每週一 07:00 檢測
8. `Private Route Topology` (`./scripts/network/private.sh`)：每週一 08:00 追蹤

### 5. 文件與架構契約同步 (`CLAUDE.md`, `README.md`)
- 移除 Go 1.26、Cobra 與 gosdk 之技術棧描述，確立純 Bash/Shell + Node.js (package.json) 架構。
- 更新目錄結構樹，移除 Go 模組，並明確標記純 Shell 領域腳本與 PM2 檢測排程。
- 同步領域流程與使用說明。

## 驗證計畫

1. 執行 `git rm` 刪除 Go 與 GitHub Actions 檔案。
2. 驗證 `package.json` JSON 格式合法性。
3. 執行 `npm run lint` 確認所有 Shell 腳本語法檢驗 PASS。
4. 執行 `npm test` 確認插件測試正常運作。
5. 驗證 `ecosystem.config.js` 語法合法性 (`node ecosystem.config.js` / 檢查 exports)。
6. 驗證 `CLAUDE.md` 與 `README.md` 內容精確度。
