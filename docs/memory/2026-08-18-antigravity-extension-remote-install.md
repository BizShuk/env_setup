# 2026-08-18 — Antigravity extension install 在 Remote-SSH 全數失敗

## 觸發 (Trigger)

在 ubuntu-server 的 Antigravity Remote-SSH integrated terminal 執行
`go run . install antigravity-extension`，37 個 manifest entries 全部輸出
`Installing extensions on SSH: ubuntu-server...` → `Extension '<id>' not found.`，
且第一個失敗即中止整批。

## 發現與處置 (Findings & Actions)

| # | 落差 | 影響 | 處置 |
| --- | --- | --- | --- |
| 1 | integrated terminal 設有 `VSCODE_IPC_HOOK_CLI`，`agy-ide` wrapper 因此改走 `remote-cli`，把安裝轉送到發起端 window | window 端的 gallery lookup 回報 not found，本機完全沒被安裝 | `svc.Runner` 在 `BeforeExec` 移除該變數；外部命令一律作用在本機 |
| 2 | 移除變數後 desktop CLI 寫入 `~/.antigravity-ide/extensions`，但本機只跑 Remote-SSH server，實際讀的是 `~/.antigravity-ide-server/extensions` | 安裝成功但 IDE 看不到 | 新增 `svc.AntigravityExtensionsDir()`，dump/install 共用；`AGY_EXTENSIONS_DIR` 可覆寫 |
| 3 | manifest 有 6 個 extension 不存在於 Open VSX (Antigravity 的 gallery)：`bierner.markdown-yaml-preamble`、`inferrinizzard.prettier-sql-vscode`、`nhoizey.gremlins`、`peterschmalfeldt.explorer-exclude`、`tht13.html-preview-vscode`、`yahyabatulu.vscode-markdown-alert` | 單一失敗即中止，後面 31 個永遠裝不到 | install loop 遇 `*svc.ExitError` 記錄後續跑，全部跑完再彙總報錯 |

## 決策 (Decisions)

- `IDE CLI 一律作用在執行它的機器`：env_setup 是機器設定工具，被 IDE terminal
  轉送到別台 window 永遠是錯的，因此在 shared runner（唯一 concrete adapter）
  一次解決，而非各 domain 自行 workaround。
- `extensions directory 的單一擁有者是 svc.AntigravityExtensionsDir()`：判定依據為
  `~/.antigravity-ide/User`（desktop 用過）與 `~/.antigravity-ide-server/data/User`
  （server 用過）是否存在，install 執行時印出解析結果，避免 silent 裝錯地方。
- `marketplace 缺件不是 install bug`：Antigravity 的 gallery 是 Open VSX，
  VS Code marketplace 專屬 extension 只能改用 VSIX 或從 manifest 移除。

## 驗證 (Verification)

- `go test ./...`：新增 runner env-scrub、extensions-dir 解析、rejected 彙總三組測試
- `env_setup install antigravity-extension`：安裝進 `~/.antigravity-ide-server/extensions`，
  僅上表 6 個 entry 失敗並在結尾彙總
