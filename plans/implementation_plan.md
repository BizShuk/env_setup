# 專案環境設定與基礎設施彙整計劃 (Project Environment Setup and Infrastructure Summarization Plan)

本計劃旨在對 `env_setup` 專案進行全面的靜態分析與彙整，並為其撰寫 `README.md` (包含功能性需求) 與 `CLAUDE.md` (包含非功能性需求)。完成後，將執行 `setup-links.sh` 腳本建立對應的符號連結 (Symbolic Link)，以便開發與 Multi-agent 協作。

依據使用者要求，本彙整不包含 `devops/` 資料夾之內容，該部分未來將搬移至獨立的 `inf` 專案。

## 使用者審查項目 (User Review Required)

> [!IMPORTANT]
> 業務領域 (Business Domain) 定義：
> 本專案經排除 `devops/` 內容後，將被劃分為以下兩個核心業務領域。請確認是否符合您的專案定位：
> 1. `環境與開發工具配置 (Environment and Development Tooling Configuration)`: 包含 `setup/` 中的系統與軟體安裝腳本，以及 `bin/project_setup`。
> 2. `開發者實用命令列工具與腳本 (Developer Utility CLI Tools and Scripts)`: 包含 `cmd/` 的 Go 語言 Cobra 實用工具 `smain`，與 `bin/` 底下的各種維護及效能檢測腳本。

> [!WARNING]
> 本次文件生成將會建立 `README.md` 和 `CLAUDE.md`，若專案根目錄已存在這些檔案（目前檢查並不存在），則會將其內容與偵測到的新架構進行合併與覆寫。

## 開放性問題 (Open Questions)

> [!NOTE]
> 1. 是否有其他未在程式碼中體現的架構決策或開發慣例需要寫入 `CLAUDE.md`？
> 2. 根目錄底下的 `run.sh` 中有一個軟連結命令：`ln -sf $HOME/.bsah_plugin ./config`，其中 `.bsah_plugin` 拼寫是否為 `.bash_plugin` 的誤寫？我們會在文件中據實記錄，或者您希望我們在此步驟進行修正？

## 預期變更 (Proposed Changes)

---

### 專案文件生成 (Project Documentation Generation)

將於根目錄建立以下文件，並確保不使用 `**` (粗體)，改以 `backtick` 進行強調。

#### [NEW] [README.md](file:///Users/shuk/projects/env_setup/README.md)
* 彙整專案的業務領域與其領域流程（不含 `devops/`）。
* 詳述兩個業務領域的實體、進入點與處理器。
* 提供改善建議。

#### [NEW] [CLAUDE.md](file:///Users/shuk/projects/env_setup/CLAUDE.md)
* 定義專案技術棧、目錄結構與模組對應（不含 `devops/`）。
* 記錄開發指南（建置、測試、安裝、部署）。
* 整理專案現有的技術慣例（錯誤處理、命名規範等）。

#### [NEW] [implementation_plan.md](file:///Users/shuk/projects/env_setup/plans/implementation_plan.md)
* 本實作計劃書。

---

## 驗證計劃 (Verification Plan)

### 自動化測試 (Automated Tests)
* 無特定自動化測試，但將在產出 `README.md` 與 `CLAUDE.md` 後執行 `setup-links.sh` 腳本：
  `bash /Users/shuk/.gemini/config/skills/summarize/setup-links.sh /Users/shuk/projects/env_setup`
* 檢查符號連結是否正確建立：
  `AGENTS.md` -> `CLAUDE.md`
  `.geminiignore` -> `.gitignore`

### 手動驗證 (Manual Verification)
* 驗證生成的文件目錄結構與業務領域的對應性。
* 使用 `ls -la` 檢查軟連結的有效性。
