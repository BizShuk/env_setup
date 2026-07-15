# 2026-07-15-env-setup-plan-revision.md

> 對 `plans/2026-07-08-env-setup-structural-cleanup.md` 的 audit 修正 (re-audit)。
> 觸發: 2026-07-15 盤點發現 plan 內容、README.todo 聲明、磁碟實況三方面有脫節。
> 本文作為本輪的 source of truth；原 plan 保留作為 historical audit 與 lineage 引用。
> 對應 `README.todo` 之 `<structural-cleanup>` 段落。

## 1. TL;DR

- `README.todo` 已將 Phase 1-6 全部標 `[x] @Completed` (2026-07-09 16:36–17:10 區間)。
- **但** plan §11 與 `README.todo` 對「已完成項目」的描述、磁碟實況三者有出入。
- 仍有 4-5 個真實 pending items 須修（§4），其中 2 個屬隱私 closure。
- plan 內部矛盾 2 處（§5）。
- 新發現 4 項（§3），包含 `pkg/mac/README.backup.md` 是回歸。
- 下一步工作定義於 Phase 7（§6）。

## 2. Step 對齊 — plan §11 vs README.todo vs 磁碟

| Plan Step | 計劃內容 | README.todo 狀態 | 磁碟實況 (2026-07-15 盤點) | 結論 |
| --- | --- | --- | --- | --- |
| 1.1 | 新建 `bin/README.md` | [x] | `bin/README.md` (2397 bytes, Jul 9) | 一致 |
| 1.2 | 新建 `docs/bin_index.md` | [x] | `docs/bin_index.md` (11740 bytes, Jul 9) | 一致 |
| 1.3 | 改 `README.md` 移除 `cmd/` `smain` | [x] | `README.md` 內容已更新（grep `cmd/` 仍 hit，但只在歷史歸檔段） | 大致一致（殘留於 archive 段，可接受） |
| 1.4 | 改 `CLAUDE.md` 移除 Cobra/logrus | [x] | `CLAUDE.md` 不含 Cobra/logrus；含 `bin/<area>/<tool>` 慣例 | 一致 |
| 1.5 | spec 改名 `20260217-agent-dir-rename.md` | [x] | 檔名已是新名 | 一致 |
| 1.6 | spec `20260218-monitoring-system-update.md` 標 `OUT_OF_SCOPE` | [x] (推論, 未明列) | 標頭未驗（grep 確認存在） | 待驗 |
| 1.7 | 兩份舊 plan 移 `archive/`（或 git rm） | [x] | `git status` 顯示已 `deleted:` 但未 commit | ⚠️ todo 標完成，磁碟有 uncommitted deletion |
| 1.8 | 改 `bin/system/README.md` 標題 | [x] (推論) | 未驗內容 | 待驗 |
| 2.1 | `bin/bash/settings.sh` 移除 `passwd`/`email` | [x] | line 9-14 改為 source `~/.config/env_setup/settings.private.sh` | 一致；下游依賴（見 §4.1）未消解 |
| 2.2 | 刪 `bin/bytedance_setup.sh` | [x] | 不存在 | 一致 |
| 2.3 | `.gitignore` 加 4 條規則 | [x] | `settings.private.sh`, `.bash_local`, `*.bak`, `**/.DS_Store` 已加入 | 一致 |
| 2.4 | `.bashrc` 移除 `ANTHROPIC_AUTH_TOKEN` | 未明示 | `.bashrc` 內 token 狀態未驗 | 待驗 |
| 2.5 | 個人 alias 改 `~/.bash_local` | [x] (Q4 答) **CANCELLED** | 描述改為「token 變數在 `~/.bash_local`，alias 仍留 `.bash_aliases` 引用 env var」 | 一致（但 §4.3.4 文字未對齊，見 §5.1） |
| 3.1 | 刪 `bin/git-secret` | [x] | 不存在；`docs/notes/git-secret.md` 提供遷移說明 | 一致 |
| 3.2 | `pkg/ctags-5.8/` 改 submodule | [x] | `.gitmodules` 有條目；`scripts/ctags_setup.sh` 已 brew fallback；本地 `pkg/ctags-5.8/` 不存在（未 `git submodule update`） | ⚠️ 設定完成；本地未初始化（見 §4.2） |
| 3.3 | 刪 3 個 dead system files | [x] | `system_performance.sh`/`raspi-config`/`system_service` 全不存在 | 一致 |
| 3.4 | 移除 `tmp/doas-install.sh` | [x] | 不存在；走 `archive/` 或直接 `rm`（README.todo 走 archive；plan §11.1 寫直接 rm） | 一致 |
| 3.5 | 搬 7 份 `pkg/linux/*.md` | [x] | 7 份 markdown 在 `docs/notes/ubuntu_note_*.md`（**非** `pkg/linux/notes/`） | ⚠️ 與 plan §11.1 描述「落入 `pkg/linux/notes/`」不符；§11.2 與實際一致（見 §5.2） |
| 3.5b | 搬 `Linux_kernel_structure.png` → `docs/notes/` | [x] (推論) | `docs/notes/Linux_kernel_structure.png` (1135597 bytes) | 一致 |
| 3.6 | `pkg/ufw/` 刪；`pkg/sysctl/` → `docs/templates/sysctl/` | [x] | 兩目錄均不存在於 `pkg/`；`docs/templates/sysctl/` 含 `pam.d`/`security`/`sysctl.conf`/`README.md` | 一致 |
| 3.7 | 移除空目錄 | [x] | `find . -type d -empty` 只 hit `config/`（已 gitignore）與 `.git/` 內部 | 一致；`config/` 例外保留 |
| 3.8 | 刪 `skills/bytedance/`, `gdpa/` | [x] | 整個 `skills/` 已不存在 | 一致 |
| 4.1 | 合併 `system_link` → `run.sh` | [x] | `bin/system/system_link` 不存在；`run.sh` 處理全部 symlink（含 `system_link` 獨有的 `/etc/ssh/ssh_config`, `${HOME}/.gemini`） | 一致；目標統一為 `./tmp/`（**非** 初版 `./config/`） |
| 4.2 | 建立 `bin/mac/_lib_audit.sh` | [x] | `bin/mac/_lib_audit.sh` (3378 bytes)；`bin/_lib_audit.sh -> mac/_lib_audit.sh` symlink 存在；4 個 audit 腳本（`disk`, `launch`, `login`, `network_security`）全部 `source` 此 helper | 一致 |
| 4.3 | 三 network scanner 整合 | [x] | `bin/network/scan_network.sh` (13966 bytes, `--mode=private\|target\|topology\|topology-no-scan`) 存在；`scan_private_network`/`scan_target_network`/`scan_devices` 已刪（Q5 順帶）；**但** `bin/network_topology_scan.sh -> system/network_topology_scan.sh` 根 symlink 與 `bin/system/network_topology_scan.sh` source **仍存在** | ⚠️ partial: dispatcher 上線、舊檔刪除完成；root symlink 與原 source 為 dead path 須清（見 §4.4） |
| 4.4 | 修 `system_info:8` `BASE_DIR` bug | [x] | `BASE_DIR="$(dirname "$0")"`（已修） | 一致 |
| 4.5 | 刪 `bin/goswitch` 與 `bin/claudew` | [x] | `bin/goswitch` 不存在；`bin/claudew` **存在**（363 bytes, Jul 9） | ⚠️ **幻覺**: README.todo 寫「刪除 `bin/claudew`」與實際脫節。git log 顯示 `38e3556` 已將 `alias claudew=` 從 `.bash_aliases` **移至** `bin/claudew` 實體腳本 — 實際語意是「migrate alias→script」，非「delete」。`bin/claudew` 是 canonical 入口，**應保留**（見 §3.1） |
| 4.6 | `bin/mac/*.sh` 加 `mac_` 前綴與 `.sh` 後綴 | [x] | `mac_cleanup.sh`/`mac_extension_list.sh`/`mac_keyboard_shortcuts_{dump,restore}.sh` 已命名；audit 系列保留 `-mac.sh` 後綴（`disk_analysis-mac.sh` 等） | 一致（audit 後綴未統一前綴是合約 trade-off，可接受） |
| 4.7 | `brew_bundle_dump` 與 `mac_cleanup.sh` 改用 `settings.sh` | [x] (推論) | 未驗 source 內容 | 待驗 |
| 4.8 | `bin/backup` 與 `bin/backupSync` 整併為 `bin/backup --mode=diff|sync` | [x] (Q3 答) | `bin/backup` (3932 bytes, 含 `--sync` 模式)；`bin/backupSync -> backup` 相容 symlink | 大致一致；symlink 待下一個 commit git rm |
| 5.x | 可擴展性（`_lib_*.sh` 慣例、`bin/network/`、ecosystem 全路徑） | [x] | `bin/README.md` 與 `docs/bin_index.md` 已寫入慣例；`bin/network/` 已成立；`ecosystem.config.js` 用全路徑 | 一致 |
| 6.x | 驗證（語法、sub-tool、markdown、shellcheck） | [x] | shellcheck 未安裝於本機（跳過）；grep 確認 `cmd/`/`project_setup`/`smain` 無活躍引用 | 一致 |
| Q1 | `pkg/sysctl/`/`pkg/ufw/` 處置 | [x] | 兩目錄已刪；sysctl 內容移 templates | 一致 |
| Q2 | `agy-ide_extension_*` 處置 | [x] | 三檔案齊全（VSCode + Antigravity 共用） | 一致 |
| Q3 | `backup`/`backupSync` 整併 | [x] | 已合併為 `bin/backup`；`backupSync` 留相容 symlink | 一致 |
| Q4 | `claudew*` alias 分層 | [x] | `.bash_aliases` 內 token 變數由 `~/.bash_local` 提供；alias 本身仍留 `.bash_aliases`（含 `claudew-s`/`-b`/`-2`） | 一致 |
| Q5 | `scan_target_network` 整合 | [x] | 內聯至 `bin/network/scan_network.sh` 內部 function | 一致 |
| Q6 | `skills/{bytedance,gdpa}` 處置 | [x] | 整個 `skills/` 不存在 | 一致 |

## 3. 新發現 (Not in Original Plan)

### 3.1 `bin/claudew` 與 `bin/claudem` 是 canonical，不是應刪項目

- 磁碟實況：`bin/claudew` (363 bytes) 與 `bin/claudem` (328 bytes) 皆存在 (Jul 9)。
- `.bash_aliases` 已**無**基礎 `alias claudew=` / `alias claudem=` 行（grep 無 hit）。
- 僅 `claudew-s` / `claudew-b` / `claudew2` 變體仍為 alias 形式（依個人決策）。
- git log: `38e3556 refactor: migrate claudew and claudem aliases to standalone script files` — 語意是「alias 升格為 script」，非「delete」。
- 隱私：`bin/claudew` 引用 `$TIKTOK_API_KEY`、`bin/claudem` 引用 `$MINIMAX_API_KEY` — token 值由 `~/.bash_local` 提供，腳本本身不含明文（與 alias 同一設計）。
- **修正**：plan §4.3.1「刪除 `bin/claudew`」應改為「**保留**為 canonical；alias 已從 `.bash_aliases` 移至此（commit `38e3556`）」。README.todo Phase 4 對應行需對齊。

### 3.2 `pkg/mac/README.backup.md` 是回歸

- `pkg/mac/` 內只有 `README.backup.md` (59614 bytes, mtime Jul 15 10:42 — 今日剛動) 與 `setup.sh`/`globalp.plist`/`LaunchAgents/`/`applescript/`；**沒有** `README.md`。
- `pkg/README.md` 仍是 1120 bytes 舊版（指 mac/ 為 plist templates）。
- `git status` 顯示 `pkg/mac/README.backup.md` 已 modified（unstaged）。
- 解讀：`pkg/mac/README.md` 應被某次動作 rename 為 `README.backup.md`，但 `pkg/README.md` 沒同步。
- **建議處置**：復原 `pkg/mac/README.backup.md` → `pkg/mac/README.md`（待 §6 Step 7.5 決定）。

### 3.3 `bin/bin/` 與 `bin/utils/` 是 Go version wrapper，非遺漏

- `bin/bin/go -> ../utils/go` (Jul 5)
- `bin/utils/go -> /Users/shuk/.local/go1.26.3.darwin-arm64/bin/go` (Jun 1)
- 用途：固定 Go 版本，繞過系統 Go 切換。
- 非遺漏空目錄；plan §4.1 目標 layout 無此 wrapper — 應在 `bin/README.md` / `docs/bin_index.md` 加索引。

### 3.4 3 個 `plans/` 內舊 plan 已 git rm 但未 commit

- `git status` 顯示：
  - `deleted: plans/2026-05-22-improve-workspace.md`
  - `deleted: plans/2026-05-24-improve-workspace.md`
  - `deleted: plans/implementation_plan.md`
- README.todo Phase 1.7 已標 completed；但 git working tree 還沒 commit。
- 加上 `.gitignore` 與 `bin/vscode/settings.json` 的修改，目前 working tree 共有 5 項未 commit 變更。

## 4. 真實 pending items（plan 未涵蓋或未關閉）

### 4.1 隱私 closure 未完成（carry-over from Step 2.1）

| 位置 | 現況 | 影響 | 處置 |
| --- | --- | --- | --- |
| `bin/ssh_keygen:8` | `ssh-keygen ... -C "${email}" ...` | `${email}` 已不再由 `settings.sh` export → 執行時為空字串，會以 `-C ""` 建立 key，註解格式損壞 | 改讀 `$(git config --global user.email)`，或從 `~/.config/env_setup/settings.private.sh` 取 |
| `bin/bash/.gitconfig:5` | `email = biz.shuk@gmail.com` | 個資 commit 入 tracked repo；任何 clone 都看得到 | 改為引用環境變數（仍由 `.gitconfig.local` 注入），或整段加 comment 指示使用者移至 `~/.gitconfig` |

### 4.2 ctags submodule 未本地初始化

- `.gitmodules` 內 `[submodule "ctags-5.8"]` 已就位
- `scripts/ctags_setup.sh` 內 fallback 為 `brew install universal-ctags`
- 本地 `pkg/ctags-5.8/` 不存在
- 影響：若使用者 clone 後想用 vendored 5.8 build，需 `git submodule update --init --recursive`
- 若 upstream URL (https://git.code.sf.net/p/ctags/code) 已 dead，從 `.gitmodules` 移除條目（scripts 已 brew fallback，不影響日常使用）

### 4.3 Network scanner dead path（Step 4.3 partial）

- 仍存在：
  - `bin/network_topology_scan.sh -> system/network_topology_scan.sh`（root symlink）
  - `bin/system/network_topology_scan.sh`（source, 18117 bytes）
- 現狀：dispatcher `bin/network/scan_network.sh` 已是實際入口；root symlink 與原 source 屬於「保留但不再被呼叫」狀態
- 影響：執行 `bin/network_topology_scan.sh` 仍會跑（功能等同 dispatcher `--mode=topology`）；對未來協作者是 dead call path
- 處置：刪 root symlink；將 source rename 為 `_scan_topology_legacy.sh` 或加 banner 提示用 dispatcher

### 4.4 `plans/` 內 3 個 old plan 的 uncommitted deletion

- 見 §3.4
- 處置：commit 此批次刪除（與 `.gitignore` / `bin/vscode/settings.json` 修改一同提交）

### 4.5 `pkg/mac/README.backup.md` 處置

- 見 §3.2
- 待決定：復原 / archive / 刪除

## 5. Plan 內部矛盾 2 處

### 5.1 §4.3.4 與 Step 2.5 cancellation 自相矛盾

- §4.3.4 寫：「`bin/bash/.bashrc`, `bin/bash/.bash_aliases`, `bin/bash/.bash_function` 內個人化片段 (`claudew*`, `codexm`) 改以 `source ~/.bash_local` 包裝」
- Step 2.5 已 `[x] CANCELLED 2026-07-08`，理由：「隱私敏感值已由 Step 2.1 的 `settings.private.sh` 機制承載」
- 衝突：§4.3.4 對應描述是 Step 2.5 原計劃，現應失效
- **修正**：§4.3.4 改為「不適用（Step 2.5 cancelled）；敏感值改由 `~/.config/env_setup/settings.private.sh` 提供」

### 5.2 §11.1 Step 3.5 路徑與實際不符

- §11.1 Step 3.5 寫「7 份 markdown 落入 `pkg/linux/notes/`」
- §11.2 已承認「`docs/notes/` 不再急迫；待 `Linux_kernel_structure.png` 一併成立」
- 實況：7 份 markdown 在 `docs/notes/ubuntu_note_*.md`，`pkg/linux/` 只剩 `rc.local`
- **修正**：§11.1 Step 3.5 改為「7 份 markdown → `docs/notes/ubuntu_note_*.md`；`pkg/linux/` 不再生 notes 子目錄」

## 6. 新增 Phase 7 — 閉環與死路徑清理

### Phase 7 — 閉環 (closure)

- [ ] Step 7.1：刪除 `bin/network_topology_scan.sh`（root symlink）；`bin/system/network_topology_scan.sh` 加 banner `[DEPRECATED: use bin/network/scan_network.sh --mode=topology]` 後保留為 legacy reference，或 git rm 後由 dispatcher 與 docs 取代
- [ ] Step 7.2：`bin/ssh_keygen:8` 改讀 `$(git config --global user.email 2>/dev/null || echo "noreply@local")`；fallback 為 `noreply@local` 而非空字串
- [ ] Step 7.3：`bin/bash/.gitconfig:5` 移除 `email = biz.shuk@gmail.com` 行；改為註解指示 `git config --global user.email "<your-email>"`
- [ ] Step 7.4：commit `.gitignore`, `bin/vscode/settings.json`, 3 個 `plans/` 內舊 plan 的 deletion, `pkg/mac/README.backup.md` 修改（單一 commit 或依邏輯分批）
- [ ] Step 7.5：決定 `pkg/mac/README.backup.md` 處置（建議：復原為 `pkg/mac/README.md`，並同步更新 `pkg/README.md` 索引）
- [ ] Step 7.6：驗證 `pkg/ctags-5.8/` upstream URL；若 dead，從 `.gitmodules` 移除條目（scripts 已 brew fallback，移除 submodule 不影響日常）
- [ ] Step 7.7：在 `bin/README.md` 與 `docs/bin_index.md` 加 `bin/bin/` + `bin/utils/` Go wrapper 索引
- [ ] Step 7.8：對 §5 兩處矛盾套用文字修補；commit 作為 plan revision metadata

### Phase 8 — 第 7 輪 audit (re-revision)

- [ ] Step 8.1：完整執行 `bin/system/system_info`, `bin/mac/*_audit-mac.sh`, `bin/network/scan_network.sh --mode=topology-no-scan` 三類入口，確認 Phase 4-7 修改未引入回歸
- [ ] Step 8.2：`git grep -nE 'biz\.shuk|gmail\.com|TIKTOK_API_KEY=[^$]'` 確認無明文個資殘留（排除 `archive/`、`README.todo`、`.bash_aliases` 中的 env var 引用）
- [ ] Step 8.3：`bin/bash/.gitconfig` 改動後，重新 `git config --local include.path ../path/to/.gitconfig` 驗本地 `.git/config` 仍能 parse

## 7. 編輯 patch（套用至原 plan）

下列 patch 對應 §2 / §4 / §5 的修正，全部套用後原 plan 內容與本文 §1 TL;DR 一致。

### Patch A — §4.3.1 改述「刪除 `bin/claudew`」

```diff
- - `bin/claudew` (個人 alias, 與 `bin/bash/.bash_aliases:126` 重複)
+ - `bin/claudew` (alias 已從 `.bash_aliases` 升格為實體腳本, commit `38e3556` 為「migrate」語意, **保留為 canonical 入口**)
```

### Patch B — §4.3.4 同步 Step 2.5 cancellation

```diff
- - `bin/bash/.bashrc`, `bin/bash/.bash_aliases`, `bin/bash/.bash_function` 內個人化片段 (`claudew*`, `codexm`) 改以 `source ~/.bash_local` 包裝；具體值留個人層級
+ - （已 by Step 2.5 CANCELLED）敏感值改由 `~/.config/env_setup/settings.private.sh` 提供；alias 本身保留於 `.bash_aliases` 引用 env var
```

### Patch C — §11.1 Step 3.5 路徑修正

```diff
- | 3.5 | 搬移 `pkg/linux/*.md` | 7 份 markdown 落入 `pkg/linux/notes/`（**非**初版之 `docs/notes/`） |
+ | 3.5 | 搬移 `pkg/linux/*.md` | 7 份 markdown → `docs/notes/ubuntu_note_*.md`；`pkg/linux/` 不再生 notes 子目錄 |
```

### Patch D — §11.1 補入 §2 / §3 新發現的 step

新增以下列（插入於 4.1 之前）：

```markdown
| 4.0a | ctags submodule URL 驗證 | `.gitmodules` 條目已就位；本地 `pkg/ctags-5.8/` 未初始化；待 fallback URL 驗證 |
| 4.0b | bin/bin + bin/utils wrapper 索引 | `bin/bin/go -> ../utils/go -> /Users/.../bin/go` Go version wrapper 建立 |
| 4.0c | bin/claudew 與 .bash_aliases alias 同步 | commit `38e3556` 已將 `alias claudew=` 從 `.bash_aliases` 移至 `bin/claudew` 實體腳本；`bin/claudem` 同；保留為唯一入口 |
```

### Patch E — §9 開放問題新增 Q7-Q10

```markdown
- Q7: `bin/ssh_keygen:8` 之 `${email}` 在 `settings.sh` 不再 export 後, 現行為為空字串。是否改讀 `git config user.email` 或 fallback 到 `noreply@local`？
- Q8: `pkg/mac/README.backup.md` 是否應復原為 `pkg/mac/README.md`, 或歸入 `archive/`?
- Q9: `pkg/ctags-5.8/` submodule URL (https://git.code.sf.net/p/ctags/code) 是否仍活著? 若否應從 `.gitmodules` 移除?
- Q10: 3 個 `plans/` 內 old plan 與 `pkg/mac/README.backup.md` 修改是否同 commit?
```

### Patch F — §5 加 Phase 7 入口

於 Phase 6 之後插入 Phase 7 與 Phase 8（見 §6）。

## 8. 引用與對應

- 原 plan: `plans/2026-07-08-env-setup-structural-cleanup.md`
- 對應 todo: `README.todo` `## <structural-cleanup>` 段 + `## Open Questions`
- 對應 commits:
    - `7799639` — Phase 3 vendored removal + bin scripts `.sh` rename + docs 重組
    - `38e3556` — claudew/claudem 升格為實體腳本
    - `a4b52b4` — README backup 政策 + `.npmrc` gitignore
    - `43cec1f` — sidebar toggle keybinding + Codex uninstall
    - `fac8840` — keybinding group 導覽
- 對應記憶 hooks:
    - `claude-mem:claude-mem:babysit` 觀察紀錄（如有後續可加入新發現分類）
- 修改本文前請先 `git fetch` 與 `git log --oneline -20` 確認 commits 對應盤點結果

## 9. 執行紀錄

- 2026-07-15：建立本文，作為 Phase 1-6 落後 audit 的 source of truth
- 預期 2026-07-15 內完成 Phase 7（Step 7.1-7.4 最急）
- 待 Phase 7 commit 完成後, 將 §11 之類比更新至原 plan（保留本文作為 audit chain）
