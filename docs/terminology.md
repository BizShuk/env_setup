# 術語表 (Terminology)

## Process Execution Domain

| 術語 | 定義 |
| --- | --- |
| Process Runner | `svc.Runner`；以 go-cmd 管理 external process lifecycle，保留 byte-oriented stdin/stdout/stderr，並在 context cancellation 時停止 process group。 |
| Process Exit Error | external command 正常啟動但以 non-zero code 結束時回傳的 structured error；保留 command name 與 exit code。 |

## Cleanup Domain

| 術語 | 定義 |
| --- | --- |
| Cleanup Item | 可獨立列出、量測、確認與套用的一個清理單位。每個 item 有穩定 ID、size、description 與 availability。 |
| Preview Mode | `env_setup cleanup` 的預設模式；只建立並顯示 cleanup plan，不讀取 confirmation，也不修改檔案。 |
| Apply Mode | `env_setup cleanup --apply`；顯示相同 plan 後逐項詢問 `[y/N]`，只執行明確回答 `y` 或 `yes` 的 item。 |
| Exact Target | Preview discovery 已解析完成的實際 path。Apply 使用同一份 snapshot，不重新展開 glob；若 target 本身是 directory，會清除該 directory 的 subtree。 |
| Command Action | 透過 argument array 執行的 external command（例如 `go clean -cache`），不經 shell interpolation。無法可靠估算 size 時顯示 `N/A`。 |

## Uninstall Domain

| 術語 | 定義 |
| --- | --- |
| Codex Uninstall Plan | `env_setup uninstall codex` 在 preview 時建立的 immutable item snapshot；包含 exact filesystem paths 與 matching user launchd labels，預設不修改 machine state。 |
| Codex Uninstall Apply | `env_setup uninstall codex --apply`；逐一詢問 available targets，只有回答 `y` 或 `yes` 的 item 才會執行，且 apply 不重新展開 glob。 |
| Optional Uninstall Scope | `--with-codexbar` 將 CodexBar app 納入 plan；`--purge-system` 將 matching `/Library` launchd files 與 `/etc/codex` 納入需要 `sudo` 的 plan。兩者都不會隱含啟用 apply。 |

## Backup Domain

| 術語 | 定義 |
| --- | --- |
| Backup Domain | 一個 macOS `defaults` 設定網域及其人類可讀說明。 |
| Backup Manifest | `~/.config/env_setup/mac_backup_domains.json`，定義要處理的 Backup Domains。 |
| Backup Snapshot | `~/.config/env_setup/data/backup/mac/` 下由 `env_setup backup` 匯出的 plist 與 metadata；`backup list` 的 latest backup date 以 metadata timestamp 為準，legacy snapshot 缺少 metadata 時 fallback 至最新 plist modification time。 |

## System Information Domain

| 術語 | 定義 |
| --- | --- |
| Information Command | `env_setup system` 下的一種系統資訊分類，例如 `cpu`、`memory` 或 `network`；實際執行入口固定為其 `show` child command。 |
| Aggregate Show | `env_setup system show`；依 catalog 順序執行全部 10 個 Information Commands。 |
| Native Probe | `svc/system/<information>.go` 中負責 macOS/Linux command selection、output parsing 與 presentation 的 Go implementation。 |
| Command Runner | `svc/system.Runner`；system probes 與 Process Runner 之間的一方法 consumer boundary，可注入 tests。 |
| Disk Verification | `env_setup system disk verify <volume-path>`；macOS-only command，先確認 write operation，再依序執行 `diskutil info`、`f3write` 與 `f3read`。 |
| F3 | Fight Flash Fraud；以 write/read test files 驗證 removable media 的實際容量與資料完整性。Verification 會使用目標 volume 的可用空間。 |

## Manifest Sync Domain

| 術語 | 定義 |
| --- | --- |
| Mac Manifest | `env_setup dump mac` 寫入的 `scripts/Brewfile`；包含目前 Homebrew taps、formulae、casks 與可取得的 Mac App Store entries。 |
| IDE Extension Manifest | `env_setup dump vscode-extension|antigravity-extension` 寫入的 tracked extension ID 清單；輸出固定排序、去重並以 newline 結尾。 |
| Atomic Manifest Write | 先完整取得並正規化 extension output，再於目標目錄建立 temporary file 並 rename；external command 失敗時不覆寫既有 manifest。 |
| Antigravity Extension Install | `env_setup install antigravity-extension`；逐項以 `--force` 安裝 manifest entries，marketplace 沒有的 entry 只記錄不中斷，列出 manifest 外的 installed extensions，且只有明確回答 `y/Y` 才會移除它們。 |
| Antigravity Extensions Directory | `agy-ide` 實際讀寫的 extensions 目錄；只跑 Remote-SSH server 的機器為 `~/.antigravity-ide-server/extensions`，desktop 機器維持 CLI 預設，`AGY_EXTENSIONS_DIR` 可覆寫。 |

## Network Scan Domain

| 術語 | 定義 |
| --- | --- |
| Private Scan | `env_setup network private [target]`；沿 traceroute 收集 RFC1918/CGNAT hops，以 public-to-local 順序掃描其 `/24` subnets，並產出 topology file。 |
| Target Scan | `env_setup network target [cidr]`；優先以 nmap host discovery 列出 live hosts，缺少 nmap 時只對 `/24` 或更小的 IPv4 network 使用 bounded concurrent ping fallback。 |
| Topology Layer | 一個由 private route hop 推導的 `/24` subnet，以及排除 route hops 後的 discovered hosts、open services 與 OS hint。 |
| Network Runner | `svc/network.Runner`；network service 與 Process Runner 之間的一方法 consumer boundary，可注入 tests。 |
