# `~/.bash_local` 個人化變數範本 (Personal Private Variables Template)

> 為避免 `TIKTOK_API_KEY` / `MINIMAX_API_KEY` 等私密 token 進入 git,
> 這些私密變數一律放至 `${HOME}/.bash_local` (git-ignored)。
> `bin/bash/.bash_aliases` 會自動 `source` 此檔 (若存在) 並使用其中定義的變數。

## 範本 (Snippet)

```bash
# ~/.bash_local — 個人層級 shell 私密變數設定 (git-ignored)
# 此處僅存放密碼、金鑰等敏感資訊，不存放 alias

# 1. 私密 API token (絕不入 git)
export TIKTOK_API_KEY="<your-token>"
export TIKTOK_API_KEY2="<your-second-token>"
export HF_TOKEN="<your-huggingface-token>"
export MINIMAX_API_KEY="<your-minimax-token>"

# 2. 其他個人化環境變數
# export MY_SECRET_TOKEN="<value>"
```

## 載入與預配置 alias (Load & Pre-configured Aliases)

`bin/bash/.bash_aliases` 內已預先配置好 `claudew*` 與 `claudem*` 等 alias，並引用 `~/.bash_local` 載入的變數：

```bash
# 載入個人化私密環境變數/密碼 (若 ~/.bash_local 存在)
if [ -f "${HOME}/.bash_local" ]; then
    # shellcheck disable=SC1090
    . "${HOME}/.bash_local"
fi

# 以下 claudew* / claudem* alias 預配置，使用來自 ~/.bash_local 的私密 API token (TIKTOK_API_KEY, MINIMAX_API_KEY 等)
alias claudew='ANTHROPIC_AUTH_TOKEN=$TIKTOK_API_KEY claude --allow-dangerously-skip-permissions --settings ~/projects/cc-plugin/config/llmbox.json'
alias claudew-s='ANTHROPIC_AUTH_TOKEN=$TIKTOK_API_KEY claude --allow-dangerously-skip-permissions --effort max --model glm-5.2 --settings ~/projects/cc-plugin/config/llmbox.json -p "look whole project for consistency, remove redundancy, structural, scalable. make a plan to ./plans/ and add an entry in README.todo"'
alias claudew-b='ANTHROPIC_AUTH_TOKEN=$TIKTOK_API_KEY claude --allow-dangerously-skip-permissions --effort max --model glm-5.2 --settings ~/projects/cc-plugin/config/llmbox.json -p "evlauate current business scope and find out high value aspects. make a plan to ./plans/ and add an entry in README.todo"'
alias claudew2='ANTHROPIC_AUTH_TOKEN=$TIKTOK_API_KEY2 claude --allow-dangerously-skip-permissions --settings ~/projects/cc-plugin/config/llmbox.json'
alias claudem='ANTHROPIC_AUTH_TOKEN=$MINIMAX_API_KEY claude --allow-dangerously-skip-permissions --settings ~/projects/cc-plugin/config/minimax.json'
```

## 為何這樣分層

| 位置 | 用途 | git 追蹤 |
|---|---|---|
| `bin/bash/.bash_aliases` | 共享與預配置 alias (`claude` / `claudew` / `codexm` 等) | ✅ |
| `~/.bash_local` | 僅存放個人 token 與私密金鑰 (絕不包含 alias) | ❌ (`.gitignore` 已加) |
| `bin/bash/settings.sh` | 共用環境變數 (`REPO_DIR`, `REPO_SCRIPTS`, `OS`, `ARCH`) | ✅ |
| `~/.config/env_setup/settings.private.sh` | 共用環境變數之私密值 (`passwd` / `email`) | ❌ |
