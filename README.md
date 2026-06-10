# env_setup

本專案提供一套完整的開發環境初始化設定指令集、作業系統調優腳本，以及基於 Go 語言 Cobra 框架開發的實用命令列工具，旨在建立一致且高效的本地開發環境。

## 業務領域 (Business Domains)

### 環境與開發工具配置 (Environment and Development Tooling Configuration)

提供用於 macOS 與 Ubuntu 作業系統環境的初始化、開發工具鏈（如 Go, Node.js, Ctags 等）安裝，以及 AI Agent 運作環境的目錄配置與符號連結管理。

`領域流程 (Domain Flow):`

1. 使用者執行 `scripts/` 下的特定系統腳本（例如 `mac.sh` 或 `ubuntu.sh`）以安裝基礎工具與開發庫。
2. 執行軟體專屬的安裝腳本（如 `go.sh`, `nodejs.sh`, `ctags_setup.sh`）來建立程式語言開發與輔助工具環境。
3. 執行 `run.sh` 建立本地設定檔案的軟連結。

`核心實體 (Key Entities):` `環境設定指令檔 (Setup Scripts)`, `專案配置檔 (Project Configuration)`, `代理配置目錄 (Agent Configuration Directory)`

`相關處理器 (Related Handlers):` [mac.sh](file:///Users/shuk/projects/env_setup/scripts/mac.sh), [ubuntu.sh](file:///Users/shuk/projects/env_setup/scripts/ubuntu.sh), [bash_env_setup.sh](file:///Users/shuk/projects/env_setup/scripts/bash_env_setup.sh)

---

### 開發者實用命令列工具與腳本 (Developer Utility CLI Tools and Scripts)

提供開發者日常維護、系統狀態檢測、資料備份以及便捷指令，並包含一個以 Go 語言基於 Cobra 框架開發的命令列工具 `smain`，用以執行運算、網頁擷取、目錄列表及本地設定管理。

`領域流程 (Domain Flow):`

1. 使用者在終端機中呼叫 `bin/` 底下的實用指令（如 `mac_cleanup` 清理磁碟, `scan_private_network` 掃描網段）或是呼叫 `run.sh` 建立軟連結。
2. 使用者在 `cmd/` 目錄中編譯並執行 `smain` 命令列工具。
3. `smain` 透過 `RootCmd()` 解析子命令（如 `hello`, `greet`, `calc`, `fetch`, `ls`, `config`），並調用對應的業務處理器（如 `readConfig()`、`http.Get()` 等）執行運算，最後將結果呈現於終端機。

`核心實體 (Key Entities):` `命令列工具 (CLI Command)`, `系統資訊 (System Information)`, `組態設定 (Configuration Settings)`

`相關處理器 (Related Handlers):` [main.go](file:///Users/shuk/projects/env_setup/cmd/main.go), [calc.go](file:///Users/shuk/projects/env_setup/cmd/calc.go), [config.go](file:///Users/shuk/projects/env_setup/cmd/config.go), [fetch.go](file:///Users/shuk/projects/env_setup/cmd/fetch.go), [greet.go](file:///Users/shuk/projects/env_setup/cmd/greet.go), [hello.go](file:///Users/shuk/projects/env_setup/cmd/hello.go), [list.go](file:///Users/shuk/projects/env_setup/cmd/list.go), [ls.go](file:///Users/shuk/projects/env_setup/cmd/ls.go), [mac_cleanup](file:///Users/shuk/projects/env_setup/bin/mac_cleanup), [run.sh](file:///Users/shuk/projects/env_setup/run.sh)

---

## 領域關聯 (Domain Relationships)

`環境與開發工具配置 (Environment and Development Tooling Configuration)` 是專案運作的基石。在環境配置完成（如安裝 Go 語言與相關 Ctags 軟體）後，`開發者實用命令列工具與腳本 (Developer Utility CLI Tools and Scripts)` 才能順利編譯並執行。特別地，`smain` 命令列工具本身在執行時依賴本地的 `config.json` 檔案，而環境初始化腳本與 `run.sh` 則為其連結與設定提供所需的環境變數與目錄對照。

## 使用方式 (Usage)

### 1. 環境與開發工具配置
在新的 macOS 或 Ubuntu 環境中，依序執行對應的安裝腳本：
```bash
# macOS 系統初始化
./scripts/mac.sh

# 執行軟連結設定
./run.sh
```

### 2. 開發者實用命令列工具與腳本
編譯並使用 `smain` 命令列工具：
```bash
# 切換至 cmd 目錄並編譯
cd cmd
go build -o smain

# 使用 greeting 命令
./smain greet --name Shuk

# 執行簡易計算 (add 或 sub)
./smain calc --num1 10 --num2 5 --operation add

# 設定或讀取組態
./smain config set --key theme --value dark
./smain config get --key theme
```

執行系統維護腳本：
```bash
# 清理 macOS 系統垃圾
./bin/mac_cleanup

# 掃描本地私有網路
./bin/scan_private_network
```

## 改善建議 (Improvement Suggestions)

Based on codebase analysis:

- [ ] `整合編譯與初始化腳本`：目前 Go 工具 `smain` 的建置與全域環境初始化獨立，建議將 `smain` 的編譯與專案初始化腳本 `bin/project_setup` 或 `run.sh` 整合，簡化開發者建置流程。
- [ ] `修正設定檔與指令拼寫錯誤`：根目錄的 `run.sh` 中包含 `ln -sf $HOME/.bsah_plugin ./config`，其中的 `.bsah_plugin` 疑為 `.bash_plugin` 的拼寫錯誤，建議統一與修正。
- [ ] `加強 smain 的錯誤處理與單元測試`：目前 `cmd/` 底下的命令處理常直接輸出錯誤訊息至終端機，缺少標準的錯誤處理管道與單元測試，建議導入 `golangci-lint` 並新增對應的單元測試以提升穩定度。
