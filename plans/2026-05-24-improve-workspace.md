# env_setup 工作區改善計劃 (Workspace Improvements) Implementation Plan

> `For agentic workers:` REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

`Goal:` 審查、驗證並修復 `env_setup` 專案中的安裝與清理腳本錯誤、優化設定檔讀寫路徑、增加 Zsh 終端機支援、升級 `golangci-lint` 與 OpenSSL 編譯版本、以及為 Go 命令列工具 `smain` 新增單元測試。

`Architecture:` 逐一修正 Bash 腳本中的拼寫與路徑問題；將 Go 設定檔路徑全域化至使用者 Home 目錄下；在設定腳本中增加對 Zsh 的支援；為 Go CLI 專案新增單元測試；優化 macOS 清理腳本以包含確認提示；在 Linux / macOS 系統檢測上引入 `ip addr` 備用方案。

`Tech Stack:` Go 1.25.4, Cobra, Bash, Go testing framework

---

### Task 1: 安裝指令檔拼寫與路徑修正 (Setup Scripts Typo and Path Fixes)

`Files:`
- Modify: `setup/mac.sh`
- Modify: `run.sh`
- Modify: `bin/project_setup`
- Modify: `setup/vim.sh`
- Modify: `setup/webmin.sh`

- [ ] `Step 1: 修改 setup/mac.sh 中無效的 Go 腳本呼叫`
  將 `setup/mac.sh` 第 20 行的 `./go_setup.sh` 修改為 `./go.sh`。

- [ ] `Step 2: 修改 run.sh 中的軟連結來源拼寫錯誤`
  將 `run.sh` 第 4 行的 `.bsah_plugin` 修正為 `.bash_plugin`。

- [ ] `Step 3: 修改 bin/project_setup 中的日誌輸出`
  將 `bin/project_setup` 第 19 行的 `Moving .agent directory to .agent...` 修正為 `Moving .agent directory to .agents...`。

- [ ] `Step 4: 重命名 troubleshotting 目錄`
  將專案根目錄下的 `troubleshotting` 目錄重新命名為 `troubleshooting`。

- [ ] `Step 5: 修改 setup/vim.sh 中的無效目錄刪除路徑與 Python 依賴，並更新 Vim 版本至 v9.1.0`
  - 修改 `source "${HOME}"/settings.sh` 為 `source "$(dirname "$0")/settings.sh"`。
  - 移除 `source ~/projects/ubuntu_setup/alias/python-config.sh` 的依賴。
  - 使用內建檢測方式獲取 `python_config_dir`。
  - 將 `VIM_VER` 更新為 `v9.1.0`。
  - 修改清理步驟為刪除正確的解壓目錄 `vim-${VIM_VER:1}`。
  ```bash
  # 修正後的 python_config_dir 獲取與清理邏輯
  if command -v python3-config &>/dev/null; then
      python_config_dir=$(python3-config --configdir)
  elif command -v python-config &>/dev/null; then
      python_config_dir=$(python-config --configdir)
  else
      python_config_dir=$(python3 -c "import sysconfig; print(sysconfig.get_config_var('LIBPL'))" 2>/dev/null)
  fi

  rm -rf "vim-${VIM_VER:1}" && rm -f "${VIM_VER}.tar.gz"
  ```

- [ ] `Step 6: 修改 setup/webmin.sh，在安裝結束後清理下載的暫存安裝指令檔`
  在 `setup/webmin.sh` 的末尾加入清除下載檔案的命令：
  ```bash
  rm -f webmin-setup-repo.sh
  ```

- [ ] `Step 7: 提交變更 (Git Commit)`
  ```bash
  git add setup/mac.sh run.sh bin/project_setup setup/vim.sh setup/webmin.sh
  git commit -m "fix: resolve typos, paths, and dependencies in setup scripts"
  ```

---

### Task 2: 配置邏輯與路徑優化 (Configuration Logic and Path Optimizations)

`Files:`
- Modify: `setup/settings.sh`
- Modify: `cmd/config.go`
- Modify: `bin/project_setup`
- Modify: `setup/bash_env_setup.sh`
- Modify: `setup/nodejs.sh`

- [ ] `Step 1: 修改 setup/settings.sh 的使用者程式庫目錄初始化邏輯`
  將 `setup/settings.sh` 第 53 行的軟連結建立指令替換為安全的目錄建立指令：
  ```bash
  [ ! -d "$USER_LIB" ] && mkdir -p "$USER_LIB"
  ```

- [ ] `Step 2: 修改 cmd/config.go 以使用全域設定檔路徑`
  - 新增全域變數 `configPathOverride` 用於測試隔離。
  - 新增 `getConfigPath` 函數，使用 `os.UserHomeDir()` 動態取得使用者家目錄下的 `.smain.json` 作為設定檔路徑。
  - 更新 `readConfig` 與 `writeConfig` 函數呼叫 `getConfigPath`。
  ```go
  var configPathOverride string

  func getConfigPath() (string, error) {
      if configPathOverride != "" {
          return configPathOverride, nil
      }
      homeDir, err := os.UserHomeDir()
      if err != nil {
          return "", fmt.Errorf("error getting home directory: %w", err)
      }
      return filepath.Join(homeDir, ".smain.json"), nil
  }
  ```

- [ ] `Step 3: 移除 bin/project_setup 中的忽略檔案軟連結`
  移除 `bin/project_setup` 第 49 行的 `ln -sfh .gitignore .geminiignore`。改為獨立檢查，若 `.geminiignore` 不存在則建立空檔案。

- [ ] `Step 4: 修改 setup/bash_env_setup.sh 的連結邏輯，加入 safe_link 備份機制`
  - 在 `setup/bash_env_setup.sh` 中新增 `safe_link` 函數。
  - 將所有 `ln -sf` 替換為 `safe_link`，並明確寫出目標檔案路徑。
  ```bash
  safe_link() {
      local src="$1"
      local dest="$2"
      if [ -e "$dest" ] && [ ! -L "$dest" ]; then
          echo "Backing up existing non-symlink file: $dest to $dest.bak"
          mv "$dest" "$dest.bak"
      fi
      ln -sf "$src" "$dest"
  }
  ```

- [ ] `Step 5: 修改 setup/nodejs.sh 以使用相對路徑引入設定檔`
  將 `setup/nodejs.sh` 第 4 行修改為相對路徑導入：
  ```bash
  source "$(dirname "$0")/settings.sh"
  ```

- [ ] `Step 6: 提交變更 (Git Commit)`
  ```bash
  git add setup/settings.sh cmd/config.go bin/project_setup setup/bash_env_setup.sh setup/nodejs.sh
  git commit -m "refactor: optimize configuration paths, backup mechanism and dependencies"
  ```

---

### Task 3: 終端機 Shell 支援與性能優化 (Terminal Shell Support & Performance Optimization)

`Files:`
- Modify: `setup/bash_env_setup.sh`
- Modify: `setup/nodejs.sh`

- [ ] `Step 1: 修改 setup/bash_env_setup.sh，新增對 Zsh 終端機環境的支援`
  在 `setup/bash_env_setup.sh` 的末尾加入對 Zsh 的檢測。若使用者預設使用 Zsh 或已存在 `.zshrc`，則自動在 `~/.zshrc` 中寫入對 `~/.bash_plugin` 的載入指令：
  ```bash
  if [ -f "${INSTALL_DIR}/.zshrc" ] || [ "$SHELL" = "*/zsh" ] || [ -n "$ZSH_VERSION" ]; then
      [ ! -f "${INSTALL_DIR}/.zshrc" ] && touch "${INSTALL_DIR}/.zshrc"
      if ! grep -q "bash_plugin" "${INSTALL_DIR}/.zshrc"; then
          echo -e "\n# Load env_setup plugin\n[ -f ~/.bash_plugin ] && source ~/.bash_plugin" >> "${INSTALL_DIR}/.zshrc"
      fi
  fi
  ```

- [ ] `Step 2: 修改 setup/nodejs.sh 以消除終端機啟動延遲`
  在執行 `nodejs.sh` 安裝時，預先計算好 `npm config get prefix` 的結果並靜態寫入到 `~/.bash_plugin`，取代每次開啟終端機時的動態指令呼叫：
  ```bash
  NPM_PREFIX=$(npm config get prefix)
  cat <<EOF >>~/.bash_plugin
  # [NodeJs:npm]
  export PATH=${NPM_PREFIX}/bin:\$PATH

  EOF
  ```

- [ ] `Step 3: 提交變更 (Git Commit)`
  ```bash
  git add setup/bash_env_setup.sh setup/nodejs.sh
  git commit -m "perf: add zsh support and eliminate terminal startup lag by caching npm prefix"
  ```

---

### Task 4: Go 工具與測試品質提升 (Go Toolchain & Testing Improvements)

`Files:`
- Modify: `setup/go.sh`
- Modify: `cmd/calc.go`
- Modify: `cmd/fetch.go`
- Create: `cmd/calc_test.go`
- Create: `cmd/config_test.go`
- Create: `cmd/fetch_test.go`
- Modify: `CLAUDE.md`

- [ ] `Step 1: 修改 setup/go.sh，升級 golangci-lint 安裝版本`
  將 `setup/go.sh` 第 50 行的 `golangci-lint` 安裝版本從 `v2.7.2` 更新為穩定版 `v1.60.3`。

- [ ] `Step 2: 修改 cmd/calc.go，將 flag 類型改為 Cobra 自動驗證的 IntVar 型別`
  重構 `newCalcCmd()`，直接使用 `IntVar` 旗標以利 Cobra 在解析時自動做格式與型別檢查。
  ```go
  var num1 int
  var num2 int
  var operation string
  // ...
  cmd.Flags().IntVar(&num1, "num1", 0, "First number")
  cmd.Flags().IntVar(&num2, "num2", 0, "Second number")
  cmd.Flags().StringVarP(&operation, "operation", "o", "", "Operation to perform (add or sub)")
  ```

- [ ] `Step 3: 修改 cmd/fetch.go，建立自定義的 http.Client 並加入 10 秒超時限制`
  將原先 `http.Get(url)` 重構為使用顯式宣告超時時間的 `http.Client`：
  ```go
  client := &http.Client{
      Timeout: 10 * time.Second,
  }
  resp, err := client.Get(url)
  ```

- [ ] `Step 4: 建立 cmd/calc_test.go，編寫 calc 指令單元測試`
  編寫針對加法、減法以及無效參數的 Cobra 整合與邏輯測試。
  ```go
  package main

  import (
      "bytes"
      "strings"
      "testing"
      "github.com/spf13/cobra"
  )

  func executeCommand(root *cobra.Command, args ...string) (string, error) {
      buf := new(bytes.Buffer)
      root.SetOut(buf)
      root.SetErr(buf)
      root.SetArgs(args)
      err := root.Execute()
      return buf.String(), err
  }

  func TestCalcCmd(t *testing.T) {
      root := RootCmd()
      out, err := executeCommand(root, "calc", "--num1", "10", "--num2", "5", "--operation", "add")
      if err != nil || !strings.Contains(out, "Result: 15") {
          t.Errorf("expected 15, got %q (err: %v)", out, err)
      }
      out, err = executeCommand(root, "calc", "--num1", "10", "--num2", "5", "--operation", "sub")
      if err != nil || !strings.Contains(out, "Result: 5") {
          t.Errorf("expected 5, got %q (err: %v)", out, err)
      }
  }
  ```

- [ ] `Step 5: 建立 cmd/config_test.go，編寫 config 指令單元測試`
  使用 `configPathOverride` 進行單元測試檔案隔離，確保不影響使用者實際的設定檔。
  ```go
  package main

  import (
      "os"
      "path/filepath"
      "strings"
      "testing"
  )

  func TestConfigCmd(t *testing.T) {
      tmpDir, err := os.MkdirTemp("", "config_test")
      if err != nil {
          t.Fatalf("failed to create temp dir: %v", err)
      }
      defer os.RemoveAll(tmpDir)

      configPathOverride = filepath.Join(tmpDir, "test_config.json")
      root := RootCmd()

      _, err = executeCommand(root, "config", "set", "--key", "theme", "--value", "dark")
      if err != nil {
          t.Fatalf("set failed: %v", err)
      }

      out, err := executeCommand(root, "config", "get", "--key", "theme")
      if err != nil || !strings.Contains(out, "theme = dark") {
          t.Errorf("expected dark, got %q (err: %v)", out, err)
      }
  }
  ```

- [ ] `Step 6: 建立 cmd/fetch_test.go，使用 httptest 測試 fetch 指令`
  啟動本地 mock HTTP 伺服器，模擬請求並驗證 fetch 回傳內容與超時。
  ```go
  package main

  import (
      "net/http"
      "net/http/httptest"
      "strings"
      "testing"
  )

  func TestFetchCmd(t *testing.T) {
      server := httptest.NewServer(http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
          rw.Write([]byte("mock body"))
      }))
      defer server.Close()

      root := RootCmd()
      out, err := executeCommand(root, "fetch", "--url", server.URL)
      if err != nil || !strings.Contains(out, "mock body") {
          t.Errorf("expected mock body, got %q (err: %v)", out, err)
      }
  }
  ```

- [ ] `Step 7: 執行 Go 測試確認通過`
  Run: `cd cmd && go test -v ./...`
  Expected: PASS

- [ ] `Step 8: 修改 CLAUDE.md，在 測試 (Test) 區塊中加入測試執行指令`
  更新 `CLAUDE.md` 的測試區塊為：
  ```markdown
  ### 測試 (Test)
  執行 Go 單元測試：
  cd cmd && go test -v ./...
  ```

- [ ] `Step 9: 提交變更 (Git Commit)`
  ```bash
  git add setup/go.sh cmd/calc.go cmd/fetch.go cmd/calc_test.go cmd/config_test.go cmd/fetch_test.go CLAUDE.md
  git commit -m "test: add unit tests for calc, config, and fetch commands; upgrade go linter version"
  ```

---

### Task 5: 系統與配置安全與相容性優化 (System Scripts Safety & Compatibility)

`Files:`
- Modify: `bin/mac_cleanup`
- Modify: `setup/ubuntu.sh`
- Modify: `bin/scan_private_network`
- Modify: `setup/openssl_setup.sh`
- Modify: `setup/openssl_mac_setup.sh`

- [ ] `Step 1: 修改 bin/mac_cleanup，將高風險操作改為可選並加確認提示`
  - 新增 `confirm` 輔助函數。
  - 將 `rm -rf ~/Music/*`、WeChat、WhatsApp 清理，以及 `-f` 和 `-j` 旗標中的毀滅性清理指令（如 Java 刪除、Safari 重置）包裹於確認提示中。
  ```bash
  confirm() {
      read -p "$1 [y/N]: " response
      case "$response" in
          [yY][eE][sS]|[yY]) true ;;
          *) false ;;
      esac
  }
  ```

- [ ] `Step 2: 修改 setup/ubuntu.sh，修復權限、移除廢棄套件與修正 locale 拼寫`
  - 將 `upgrade` 加上 `sudo`：`sudo apt-get update && sudo apt-get upgrade -y`。
  - 移除 `python-dev`。
  - 修正拼寫錯誤：`LC_ADDRESSE` 改為 `LC_ADDRESS`，`LC_IDENTICFICATION` 改為 `LC_IDENTIFICATION`。
  - 將 settings.sh 引入改為相對路徑。

- [ ] `Step 3: 修改 bin/scan_private_network，新增依賴檢查與 ip addr 支援`
  - 在腳本開頭加入 `traceroute` 與 `nmap` 檢查，如果未安裝則顯示錯誤並退出。
  - 新增 `get_local_ip` 等函數，優先使用 `ip addr` 指令，若無則降級使用 `ifconfig`，提高相容性。

- [ ] `Step 4: 修改 setup/openssl_setup.sh，升級編譯版本至 3.0.13`
  將 OpenSSL 版本升級至安全穩定的 `3.0.13`。

- [ ] `Step 5: 修改 setup/openssl_mac_setup.sh`
  - 修改為優先使用 Homebrew 安裝 `openssl@3`。
  - 若無 Homebrew，則偵測目前主機架構為 `darwin64-arm64-cc` 或是 `darwin64-x86_64-cc` 以動態配置編譯目標。
  - 將 OpenSSL 安裝路徑下的 `ssl/man` 修正為 3.x 版本的 `share/man`。

- [ ] `Step 6: 驗證整體腳本與指令的執行狀況`
  執行 `project_setup` 並手動檢查軟連結狀態與 Go CLI 建置。

- [ ] `Step 7: 提交變更 (Git Commit)`
  ```bash
  git add bin/mac_cleanup setup/ubuntu.sh bin/scan_private_network setup/openssl_setup.sh setup/openssl_mac_setup.sh
  git commit -m "sec: enhance safety in cleanup scripts, fix compatibility issues and upgrade openssl versions"
  ```
