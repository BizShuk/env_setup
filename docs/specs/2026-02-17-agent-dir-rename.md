# `.agent` 目錄重命名 (Agent Directory Rename)

**Date**: 2026-02-17
**Topic**: 將 `.agents` 統一為 `.agent` 以對齊 Antigravity IDE 預設路徑

## Context (背景)

Antigravity IDE 預設從 `.agent/` 讀取 rules 與 skills；當 `.agent` 為 symbolic link 時, IDE 無法穩定識別內容。早期 `bin/project_setup` 嘗試用 symlink 指向既有 `.agents/` 目錄, 造成 IDE 行為不一致。

## 變更內容 (Changes)

### `bin/project_setup`

- 偵測若 `.agent` 為 symbolic link, 刪除。
- 若 `.agents` 為實際目錄且 `.agent` 不存在, 將 `.agents` 重新命名為 `.agent`。
- 後續 `mkdir -p` 一律操作於實際目錄。

```bash
# 處理舊的 symbolic link
if [ -L ".agent" ]; then
  echo "Removing existing .agent symbolic link..."
  rm ".agent"
fi

# 將舊的 .agents 升級為 .agent
if [ -d ".agents" ] && [ ! -d ".agent" ]; then
  echo "Moving .agents directory to .agent..."
  mv ".agents" ".agent"
fi
```

## 結果 (Outcome)

`.agent` 為實際目錄 (非 symlink), Antigravity IDE 可穩定讀取 rules / skills; 既有內容從 `.agents` 無痛遷移, 不需手動重灌。

> 註: `bin/project_setup` 入口本身於 2026-07 結構清理時移除, 相關邏輯改由 `run.sh` 與 `scripts/bash_env_setup.sh` 接手 (見 `plans/2026-07-08-env-setup-structural-cleanup.md`)。
