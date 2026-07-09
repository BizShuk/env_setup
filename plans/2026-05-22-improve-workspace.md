# env_setup 工作區改進計劃 (Workspace Improvements) Implementation Plan

> ⚠️ **ARCHIVED** (2026-07-09): 本計畫涉及 `cmd/smain` (Go + Cobra)、`bin/project_setup` 等已於 2026-07 結構清理時移除的元件; 全部步驟已被 `plans/2026-07-08-env-setup-structural-cleanup.md` 取代。保留此檔僅作為歷史決策紀錄, **不再執行**。

> `For agentic workers:` REQUIRED SUB-KILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

`Goal:` 修復 env_setup 專案中的安裝腳本錯誤、最佳化設定檔路徑、增加 Zsh 支援，以及為 Go 命令列工具新增單元測試。

`Architecture:` 逐一修正 Bash 腳本中的路徑與拼寫問題；將 Go 設定檔移至使用者 Home 目錄；在設定腳本中增加對 `.zshrc` 的支援；為 Go CLI 專案新增單元測試。

`Tech Stack:` Go 1.25.4, Cobra, Bash, Go testing framework

---

### Task 1: 修復安裝指令檔的拼寫與路徑錯誤 (Fix Typo and Path Errors in Setup Scripts)

`Files:`
- Modify: `scripts/mac.sh`
- Modify: `run.sh`
- Modify: `bin/project_setup`

- [ ] `Step 1: 修改 scripts/mac.sh 中無效的 Go 腳本呼叫`
  將 `scripts/mac.sh` 中的 `./go_setup.sh` 改為 `./go.sh`。

- [ ] `Step 2: 修改 run.sh 中的拼寫錯誤`
  將 `run.sh` 中的 `.bsah_plugin` 改為 `.bash_plugin`。

- [ ] `Step 3: 修改 bin/project_setup 中的日誌輸出`
  將 `bin/project_setup` 中的 `Moving .agent directory to .agent...` 改為 `Moving .agent directory to .agents...`。

- [ ] `Step 4: 測試執行 project_setup`
  執行: `./bin/project_setup`
  驗證: 確認無錯誤輸出，且產生的軟連結正確。

### Task 2: 最佳化配置邏輯與路徑 (Optimize Configuration Logic and Paths)

`Files:`
- Modify: `scripts/settings.sh`
- Modify: `cmd/config.go`
- Modify: `bin/project_setup`

- [ ] `Step 1: 修改 scripts/settings.sh 的目錄建立邏輯`
  將 `scripts/settings.sh` 中的：
  `[ ! -e "$USER_LIB" ] && ln -s "$USER_LIB" "${HOME}/projects/env_scripts/config/"`
  替換為：
  `[ ! -d "$USER_LIB" ] && mkdir -p "$USER_LIB"`。

- [ ] `Step 2: 修改 cmd/config.go 以使用全域路徑`
  修改 `cmd/config.go` 中的 `configFileName` 和 `readConfig` / `writeConfig` 函數。
  將原本的：
  ```go
  configPath := filepath.Join(".", configFileName)
  ```
  改為讀取使用者家目錄的設定：
  ```go
  homeDir, err := os.UserHomeDir()
  if err != nil {
      return nil, fmt.Errorf("error getting home directory: %w", err)
  }
  configPath := filepath.Join(homeDir, ".smain.json")
  ```

- [ ] `Step 3: 移除 bin/project_setup 中的忽略檔案軟連結`
  移除 `bin/project_setup` 中的 `ln -sfh .gitignore .geminiignore`，改為若 `.geminiignore` 不存在則觸碰建立空檔案。

### Task 3: 擴充 Zsh 終端機環境支援 (Expand Support for Zsh Shell)

`Files:`
- Modify: `scripts/bash_env_setup.sh`

- [ ] `Step 1: 在 scripts/bash_env_setup.sh 中偵測 Zsh 並寫入配置`
  在 `scripts/bash_env_setup.sh` 末尾，新增檢測使用者預設 shell 的邏輯，如果使用者使用的是 Zsh，則在 `${INSTALL_DIR}/.zshrc` 中載入配置：
  ```bash
  if [ -f "${INSTALL_DIR}/.zshrc" ]; then
      if ! grep -q "bash_plugin" "${INSTALL_DIR}/.zshrc"; then
          echo -e "\n# Load env_setup plugin\n[ -f ~/.bash_plugin ] && source ~/.bash_plugin" >> "${INSTALL_DIR}/.zshrc"
      fi
  fi
  ```

### Task 4: Go 工具鏈品質提升 (Go Toolchain Quality Improvements)

`Files:`
- Modify: `scripts/go.sh`
- Create: `cmd/calc_test.go`
- Create: `cmd/config_test.go`

- [ ] `Step 1: 更新 golangci-lint 的安裝版本`
  修改 `scripts/go.sh` 中的 `golangci-lint` 安裝版本，將 `v2.7.2` 改為當前穩定版（例如 `v1.60.3`）。

- [ ] `Step 2: 為 cmd/calc.go 新增單元測試`
  建立 `cmd/calc_test.go`，並編寫測試程式碼：
  ```go
  package main

  import (
      "testing"
  )

  func TestCalcOperations(t *testing.T) {
      // 測試加法與減法邏輯
  }
  ```

- [ ] `Step 3: 執行測試確認通過`
  執行: `cd cmd && go test -v ./...`
  驗證: 測試 PASS。
