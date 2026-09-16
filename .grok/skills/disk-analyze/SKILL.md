---
name: disk-analyze
description: Use when disk space is running low or someone asks what is taking up space, what can be deleted, which folders are largest, or wants to reclaim space on a Mac or Linux box. Triggers on "磁碟快滿了", "空間不夠", "什麼可以刪", "清理磁碟", "disk full", "no space left on device", "largest folders", "top 20 biggest", "what is eating my disk".
---

# disk-analyze

## Overview

把整台機器的磁碟用量變成一張`可以直接照做的刪除清單`，並透過結構化的**清理確認精靈 (Cleanup Wizard)** 引導使用者安全釋放空間。

兩步驟分析：`dux scan` 產出 CSV snapshot，`dux analyze` 把 CSV 排成 top-N 候選。

核心是 `rollup 語意`：一個資料夾若`整個`都是可重建的產物 (cache, build artifact, 依賴)，
就`只列這個資料夾一行`，它底下的子檔案與子資料夾`完全不再出現`。反過來，不能整個刪的資料夾
`永遠不會被列為候選`，分析器改成`往下鑽`，去找它裡面真正能刪的部分。因此清單上每一個 byte
`只被算一次`，總計數字可以直接相信。

## When to Use

- 磁碟剩餘空間告急，需要知道`刪什麼最划算`
- 想看`最大的 20 個`檔案或資料夾，而且不要被同一棵樹的父子項目洗版
- 準備清理前想先確認`哪些是安全的，哪些要人工判斷`
- 執行清理精靈，以防誤刪個人資料與重要開發模型

`不適用`：找重複檔案 (dux 的 duplicate section 已不在主路徑)，追蹤某路徑的成長趨勢
(那是 `file_watcher` 的職責)。

## Workflow

### 1. 掃描 (Scan)

```bash
dux scan --min-size 50MB
```

掃 `$HOME`、`/tmp`、`/var`、`/usr`，寫入 `~/.config/dux/data/YYYY-MM-DD.csv`。

`門檻決定候選數量`。預設 `200MB` 在一般機器上只會留下約 400 列，top 20 可能`湊不滿`；
要湊滿 20 個候選就把 `--min-size` 降到 `50MB` 或更低。已經有當天的 CSV 就`跳過這步`，
直接分析既有檔案。若需納入應用程式目錄，加上 `--roots $HOME,/Applications`。

### 2. 分析 (Analyze)

```bash
dux analyze --top 20
```

不給參數時自動讀 `~/.config/dux/data/` 裡`最新`的 CSV。輸出分為：

- `候選清單 (Candidates)` — 依大小排序，每行含理由與 mtime，結尾給出`不重複計算`的總可回收量。
- `人工判斷 (Manual Review)` — 很大但`不能自動判定安全`的項目 (個人文件, VM image, Chrome 模型, 沙盒)。
- `保護項目 (Protected)` — 系統核心與本機開發關鍵模型 (如 Hugging Face / MLX 模型權重)，嚴禁列入刪除。

---

### 3. 清理確認精靈 (Cleanup Wizard Protocol)

> [!IMPORTANT]
> **精靈互動提問原則**：
> 1. **1 question for ok to delete**：所有判定為零風險、可自動或隨時安全重建的項目，**統一整合在單一問題中批次確認**。
> 2. **each question for something need to confirm**：對於具備使用權衡 (Trade-off) 或刪除後需重抓/重置的項目，**每一項必須獨立出一個專屬問題**單獨向使用者確認。
> 3. **protected assets**：受保護核心資產嚴禁列入任何刪除選項。

#### 提問 1：安全項目批次確認 (1 Question for OK to Delete)
將所有屬於 `whole` 等級的項目（例如：舊版 iOS DeviceSupport 符號、Go build cache、Chrome 網頁暫存、`uv/pnpm/brew/pip` 套件快取、專案 `tmp/`、應用程式日誌 `Library/Logs`）彙總為**一道多選題**：

- **呈現方式**：列出項目名稱、路徑與預估容量，並顯示「全選刪除」與個別勾選項。
- **範例**：
  > 「以下為可安全釋放的快取與暫存檔（預估釋放 ~12.8 GiB），刪除不影響日常開發與系統運作：
  > [x] iOS DeviceSupport 舊符號 (5.7 GiB)
  > [x] Go 編譯快取 (1.1 GiB)
  > [x] Google Chrome 網頁/GPU 快取 (1.2 GiB)
  > [x] 開發套件快取 uv/pip/pnpm/brew (~2.2 GiB)
  > [x] 專案 tmp 暫存檔 (866 MiB)
  > [x] 舊版 Xcode 打包檔與應用日誌 (~480 MiB)
  > 是否確認清理已勾選項目？」

#### 後續提問：條件式項目個別確認 (Each Question for Something Need to Confirm)
對於屬於 `review` 等級的大型項目，**「每一項獨立詢問一題」**，詳細告知影響與權衡：

- **Claude Desktop VM 沙盒** (例：11.0 GiB)：
  > 「是否清理 Claude Desktop VM 沙盒鏡像 (`claudevm.bundle`，約 11.0 GiB)？
  > 說明：此為 Claude 桌面端本地執行沙盒。刪除後會重置沙盒，下次若在桌面端使用本地程式碼執行時會自動重新下載。」
- **Google Chrome 本地 AI 模型** (例：4.0 GiB)：
  > 「是否清理 Google Chrome 本地 Gemini Nano 模型 (`OptGuideOnDeviceModel`，約 4.0 GiB)？
  > 說明：若未在瀏覽器中使用 Prompt API (`window.ai`)，可安全刪除；若日後需要該功能，Chrome 會在背景重新下載。」
- **Xcode Simulator Runtime 與 dyld cache** (例：16~19 GiB)：
  > 「是否清理 Xcode iOS 模擬器 Runtime 與 dyld 共用快取 (約 19.0 GiB)？
  > 說明：若主要使用實體 iPhone 進行真機測試，刪除可釋放巨量空間；日後若需模擬器，需從 Xcode Settings -> Platforms 重新下載。」
- **Go Module 下載依賴原始碼** (例：1.9 GiB)：
  > 「是否清理 Go Module 依賴原始碼快取 (`~/.local/go/pkg/mod`，約 1.9 GiB)？
  > 說明：日後執行 `go build` 或 `go test` 時會自動連網重新拉取依賴。」
- **4K 動態桌布 / 航拍影片** (例：910 MiB)：
  > 「是否刪除系統自動下載之 4K 航拍螢幕保護程式影片 (`com.apple.wallpaper/aerials`，約 910 MiB)？」
- **閒置專案的 `node_modules`** (例：各幾百 MB 至 1GB+)：
  > 「是否清理特定閒置專案之 `node_modules`？需要時執行 `pnpm install` 或 `npm install` 即可還原。」
- **閒置或無用 Application** (例：Docker.app 2.1 GiB、iWork 1.9 GiB 等)。

#### 嚴格保護清單 (Protected Items — Never Delete)
以下項目**絕對不提示刪除**，也不得納入精靈選項：
- **`~/.cache/huggingface`**：存放本地語音或 AI 模型（如 `pkg/mlx/` 服務所需之 Qwen3-ASR 與 ForcedAligner 權重）。
- **`/Library/Developer/CommandLineTools`**：系統編譯與工具鏈核心。
- **`~/projects/` 原始碼與資料庫**。
- **`~/.gemini` 與 `~/.antigravity`**：當前 Agent 工具鏈與執行環境。
- **通訊軟體本機歷史紀錄** (`LINE`, `WeChat`, `WhatsApp`)。

---

### 4. 執行與成效驗證 (Execute & Verify)

1. 根據精靈確認結果執行指定刪除指令。
2. 檢查磁碟剩餘空間前後對照：
   ```bash
   df -h /System/Volumes/Data
   ```
3. 若有需要 `sudo` 權限之項目（如 `/Library/Updates/*` 舊版安裝包 899 MiB），提供單行指令供使用者於終端機貼上執行：
   ```bash
   sudo rm -rf /Library/Updates/<id>
   ```

## Quick Reference

| 需求 | 指令 |
| --- | --- |
| 完整重掃 + 分析 | `dux scan --min-size 50MB && dux analyze` |
| 只看前 10 名 | `dux analyze --top 10` |
| 不看人工判斷段 | `dux analyze --review 0` |
| 分析舊 snapshot | `dux analyze --date 2026-09-13` |
| 只看 1GB 以上 | `dux analyze --min-size 1GB` |
| 看判定規則 | `dux analyze --show-rules` |
| 展開被合併的群組 | `dux analyze --members` |
| 連 /Applications 一起掃 | `dux scan --roots $HOME,/Applications` |

## Deletability Rules

判定表`內嵌在 binary`，用 `dux analyze --show-rules` 查看，原始檔在 `svc/rules.json`（亦備份於 `references/rules.json`）。
三個等級，`優先序 keep > whole > review`，同級內`先命中者勝`：

| 等級 | 意義 | 對 rollup 的效果 |
| --- | --- | --- |
| `keep` | 絕不可刪 (系統分割區, iCloud, 照片圖庫, keychain, CommandLineTools, 本地 AI 模型, app bundle 內部) | `整棵子樹剪掉`，不列候選也不列 review |
| `whole` | 整個資料夾都是可重建產物 (快取, 暫存, 舊符號) | `列為候選`，並壓掉所有子項目，納入**提問 1 批次確認** |
| `review` | 大但需要人工判斷 (沙盒, 本地模型, 模擬器, 個人文件) | `永不列為候選`，往下鑽找可刪子項目，納入**後續個別提問確認** |

未命中任何規則`預設為 review`，也就是`偏保守`：沒被明確認證安全的東西不會進候選清單。

`collapse`：標了這個旗標的規則，重複命中時會`合併成一行`，錨定在共同上層目錄，
顯示成 `<共同目錄>  [N × <名稱>]`。用在會在同一棵樹裡出現幾十次的 pattern
(每個 Python 版本一份 `__pycache__`，每個 simulator 一份 cache)，否則它們會洗掉整個 top-20。
`合併列不能直接刪錨點目錄`，要 `--members` 展開看實際路徑。

## Common Mistakes

| 錯誤 | 後果 | 正解 |
| --- | --- | --- |
| 直接把 CSV 依 size 排序取前 20 | 前幾名全是 `$HOME` → `Library` → `Application Support` 這種父子鏈，同一份資料被列四次 | 用 `dux analyze`，只列可整個刪的節點 |
| 把大資料夾當成可刪 | 誤刪個人文件或本機 AI 模型權重 | 只有 `whole` 等級進候選，其餘一律人工判斷 |
| 將安全項目拆成幾十個問題輪流問 | 使用者體驗極度破碎 | **1 question for ok to delete**：安全項目整合成一題批次確認 |
| 將需確認的項目打包一次刪 | 使用者在不知情下遺失 VM 沙盒或重新下載大模型 | **each question for something need to confirm**：條件式項目個別獨立出題確認 |
| 對合併列的錨點目錄下 `rm -rf` | 刪掉整個 Python 或 Containers 目錄 | 合併列先 `--members` 展開，逐個刪 |
| 把 review 段的數字加進可回收總量 | 高估數倍 | 總計`只加候選清單`，review 段不計入 |
| 用舊的 CSV 下結論 | 已經刪過的東西又出現一次 | 先確認輸出第一行的 CSV 日期，必要時重掃 |

## Permissions

macOS 上 `~/Library` 部分子目錄需要 `Full Disk Access` 才讀得到；缺權限的 root 只會記 warning，
其餘 root 照常產出。若結果明顯偏小，先確認執行的 terminal 是否已被授權。
