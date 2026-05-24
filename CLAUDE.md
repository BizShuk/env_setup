# env_setup — 技術脈絡 (Technical Context)

## 專案結構 (Project Structure)

```text
.
├── LICENSE
├── README.md
├── CLAUDE.md
├── run.sh
├── .agents/
│   ├── rules/
│   ├── skills/
│   ├── workflows/
│   └── settings.json
├── bin/
│   ├── bash/
│   ├── mac/
│   ├── system/
│   ├── vscode/
│   ├── mac_cleanup
│   ├── project_setup
│   └── scan_private_network
├── cmd/
│   ├── calc.go
│   ├── config.go
│   ├── config.json
│   ├── fetch.go
│   ├── go.mod
│   ├── greet.go
│   ├── hello.go
│   ├── list.go
│   ├── ls.go
│   ├── main.go
│   └── README.md
├── openclaw/
│   └── yuna/
├── pkg/
│   ├── ctags-5.8/
│   ├── linux/
│   ├── mac/
│   ├── sysctl/
│   └── ufw/
├── setup/
│   ├── disk/
│   ├── bash_env_setup.sh
│   ├── brew.sh
│   ├── Brewfile
│   ├── ctags_setup.sh
│   ├── git-secret.sh
│   ├── go.sh
│   ├── nodejs.sh
│   ├── openssl_setup.sh
│   └── ubuntu.sh
├── specs/
│   ├── 20260217-fix-agent-symlink.md
│   └── 20260218-monitoring-system-update.md
└── troubleshooting/
```

## 技術棧 (Tech Stack)

- Language: Go 1.25.4 (CLI), Bash/Shell (安裝與維護腳本), Python (輔助腳本)
- Framework: Cobra v1.10.1 (Go CLI 框架)
- Build tool: `go build`
- Key dependencies: `github.com/sirupsen/logrus` (Go 記錄器), `github.com/spf13/cobra` (Go 命令列解析)

## 關鍵決策 (Key Decisions)

- `環境與工具配置腳本模組化`：將安裝程序分為系統層級安裝（如 `mac.sh`, `ubuntu.sh`）與開發工具層級安裝（如 `go.sh`, `nodejs.sh`），實現低耦合與安裝步驟重用。
- `命令列工具採用 Cobra`：使用 Go 語言與 `cobra` 庫建置 CLI `smain`，易於擴充子命令，且不需要複雜的外部依賴。
- `環境設定與軟連結設計`：透過 `bin/project_setup` 生成 `.agents` 目錄，使 AI Agent 規則與工作流能在開發環境中統一存取，不因單一平台或工具而失效。

## 模組對應 (Module Mapping)

| 業務領域 (Domain)                                                      | 套件/模組 (Package/Module)    | 進入點 (Entry Point)                                   |
| ---------------------------------------------------------------------- | ----------------------------- | ------------------------------------------------------ |
| 環境與開發工具配置 (Environment and Development Tooling Configuration) | `setup/`, `bin/project_setup` | `setup/mac.sh`, `setup/ubuntu.sh`, `bin/project_setup` |
| 開發者實用命令列工具與腳本 (Developer Utility CLI Tools and Scripts)   | `cmd/`, `bin/`                | `cmd/main.go` (`main()`), `run.sh`                     |

## 開發指南 (Development Guide)

### 前置需求 (Prerequisites)

- macOS 或 Ubuntu Linux
- Go 1.25.4+
- Bash/Zsh 終端機環境

### 安裝 (Installation)

依據目標作業系統執行初始化配置：

```bash
# macOS 環境初始化
./setup/mac.sh

# 專案環境與 AI Agent 初始化配置
./bin/project_setup
```

### 建置 (Build)

建置 Go 語言實用命令列工具 `smain`：

```bash
cd cmd
go build -o smain
```

### 測試 (Test)

執行 Go 單元測試：

```bash
cd cmd
go test -v ./...
```

### 部署 (Deploy)

未偵測到部署設定。

## 慣例 (Conventions)

- 命名規範 (Naming)：
    - Shell 腳本：檔案名稱使用 snake_case（例如 `bash_env_setup.sh`），變數名稱使用 camelCase 或全大寫。
    - Go：變數與函式使用 CamelCase（例如 `newCalcCmd()`），依循 Go 官方推薦之格式。
- 錯誤處理 (Error Handling)：
    - Go：顯式錯誤檢查與提前返回（例如 `if err != nil` 則 return），確保錯誤被妥善捕捉。
    - Shell 腳本：部分關鍵配置腳本使用 `set -euo pipefail` 以確保執行失敗時立即中止。
- 記錄日誌 (Logging)：
    - Go 內部實用工具使用 `logrus` 作為日誌管理器，並以 `fmt.Println` 提供命令列輸出。
- 設定儲存 (Configuration)：
    - 使用者自訂設定寫入本地 `cmd/config.json` 進行持久化儲存。
