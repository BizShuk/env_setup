# 術語表 (Terminology)

## Cleanup Domain

| 術語 | 定義 |
| --- | --- |
| Cleanup Item | 可獨立列出、量測、確認與套用的一個清理單位。每個 item 有穩定 ID、size、description 與 availability。 |
| Preview Mode | `env_setup cleanup` 的預設模式；只建立並顯示 cleanup plan，不讀取 confirmation，也不修改檔案。 |
| Apply Mode | `env_setup cleanup --apply`；顯示相同 plan 後逐項詢問 `[y/N]`，只執行明確回答 `y` 或 `yes` 的 item。 |
| Exact Target | Preview discovery 已解析完成的實際 path。Apply 使用同一份 snapshot，不重新展開 glob；若 target 本身是 directory，會清除該 directory 的 subtree。 |
| Command Action | 透過 argument array 執行的 external command（例如 `go clean -cache`），不經 shell interpolation。無法可靠估算 size 時顯示 `N/A`。 |

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
| Command Runner | `svc/system.Runner`；system probes 與 `os/exec` 之間的一方法 boundary，可注入 tests，production 使用 context-aware OS runner。 |
| Disk Verification | `env_setup system disk verify <volume-path>`；macOS-only command，先確認 write operation，再依序執行 `diskutil info`、`f3write` 與 `f3read`。 |
| F3 | Fight Flash Fraud；以 write/read test files 驗證 removable media 的實際容量與資料完整性。Verification 會使用目標 volume 的可用空間。 |

## Manifest Dump Domain

| 術語 | 定義 |
| --- | --- |
| Mac Manifest | `env_setup dump mac` 寫入的 `scripts/Brewfile`；包含目前 Homebrew taps、formulae、casks 與可取得的 Mac App Store entries。 |
| IDE Extension Manifest | `env_setup dump vscode|antigravity` 寫入的 tracked extension ID 清單；輸出固定排序、去重並以 newline 結尾。 |
| Atomic Manifest Write | 先完整取得並正規化 extension output，再於目標目錄建立 temporary file 並 rename；external command 失敗時不覆寫既有 manifest。 |

## Network Scan Domain

| 術語 | 定義 |
| --- | --- |
| Private Scan | `env_setup network private [target]`；沿 traceroute 收集 RFC1918/CGNAT hops，以 public-to-local 順序掃描其 `/24` subnets，並產出 topology file。 |
| Target Scan | `env_setup network target [cidr]`；優先以 nmap host discovery 列出 live hosts，缺少 nmap 時只對 `/24` 或更小的 IPv4 network 使用 bounded concurrent ping fallback。 |
| Topology Layer | 一個由 private route hop 推導的 `/24` subnet，以及排除 route hops 後的 discovered hosts、open services 與 OS hint。 |
| Network Runner | `svc/network.Runner`；network service 與 external tools 之間的一方法 boundary，可注入 tests，production 使用 context-aware OS runner。 |
