# 2026-07-31 — 文件與 runtime 一致性稽核 (Consistency Check)

## 觸發 (Trigger)

commit `7e9b76e` (刪除 obsolete bin scripts) 與 `218e7d3` (shell → Go install/uninstall)
之後，`CLAUDE.md` / `README.md` / `docs/bin_index.md` 未同步；`ecosystem.config.js`
仍註冊已刪除的腳本。

## 發現與處置 (Findings & Actions)

| # | 落差 | 影響 | 處置 |
| --- | --- | --- | --- |
| 1 | `ecosystem.config.js` 註冊已刪除的 `bin/mac/disk_analysis-mac.sh` | pm2 cron 每週五必失敗 | 改為 `env_setup cleanup` preview (bare name + `args`) |
| 2 | 文件四處要求 `./build.sh`，該檔於 `2b1f3f8` 隨 `macbackup` 一併刪除 | 使用者照文件無法建置 | 使用者裁決不保留 wrapper：文件全部改為 `go build -o ~/.local/bin/env_setup .` |
| 3 | `bin/utils/go` 遺失 → `bin/bin/go` 成為 broken symlink | Go 版本鎖版 wrapper 失效 | 重建 symlink (machine-local，`bin/.gitignore` 排除) |
| 4 | `.gemini -> .agents` 指向已改名目錄 | agent 設定讀不到 | 改指 `.claude` |
| 5 | root `specs/` 與 `docs/specs/` 並存 | 同類文件兩處，必然分岔 | 4 檔移入 `docs/specs/` 並改 `YYYY-MM-DD-` 命名 |
| 6 | `CLAUDE.md` 慣例段落整段重複，且兩份對 alias 規則相衝 | 讀者無法判定何者為準 | 以實際狀態裁決：alias 全放 `.bash_aliases`，`~/.bash_local` 只放變數 |
| 7 | `.bash_aliases` source `~/.bash_local` 兩次 | 冗餘 | 移除第二個 source 區塊 |
| 8 | `README.md` 4 處硬編 `/Users/bytedance/...` | 換機即失效 | 改相對路徑 |

## 決策 (Decisions)

- `alias 的單一擁有者是 bin/bash/.bash_aliases`：`~/.bash_local` 只存 `export`。
  裁決依據是實測 —— `~/.bash_local` 內 0 個 alias、34 個變數，而 `claudew-*`
  alias 實際定義在 `.bash_aliases` 且只引用變數名，token 未入 git。
- `pm2 註冊路徑分兩類`：`bin/` script 用 `./bin/<area>/<tool>` 全路徑（pm2 會切換
  工作目錄）；已在 `PATH` 的 binary 用 bare name + `args` 陣列，與既有 `go` 任務一致。
- `docs/specs/ 是規格單一落點`：root `specs/` 不再存在，避免兩處分岔。
- `不設 build wrapper`：`go build -o ~/.local/bin/env_setup .` 已是完整指令，
  額外包一層 `build.sh` 只會多一個需要與文件同步的檔案（正是本次落差 #2 的成因）。

## 未處理 (Deferred)

- `docs/specs/2026-07-08-*.md` 與 `2026-07-15-*.md` 內文仍寫舊 `specs/` 路徑。
  此二檔是`歷史紀錄`，描述當時的決策與路徑，改寫等同竄改紀錄，故保留原文。
- `pkg/libgit2` submodule 未 init；`.gitmodules` 仍有該條目，需要時再 `git submodule update --init`。

## 可重複執行的驗證 (Repeatable Verification)

```bash
go build ./... && go test -count=1 ./...
# 結構樹每個路徑都存在
find . -path ./.git -prune -o -type l -print | while read l; do [ -e "$l" ] || echo "BROKEN: $l"; done
# 文件無死引用
git grep -n 'build.sh\|disk_analysis\|list_big_files\|check_alive\|listen_port' -- '*.md' 'ecosystem.config.js'
```
