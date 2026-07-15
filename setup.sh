#!/bin/bash
set -euo pipefail

# ============================================================================
# env_setup — interactive setup wizard (repo-root entry point)
# ============================================================================
# 逐步 (step by step) 引導本機初始化，三個階段皆 idempotent、可 Ctrl-C 中斷：
#   1. 個人資訊 (Personal Info)  -> ~/.env.profile (git-ignored)
#   2. Bash Env                  -> scripts/bash_env_setup.sh (safe_link dotfiles)
#   3. 工具逐一安裝 (Tools)      -> scripts/<installer>.sh，每項 [y/N]
#
# 慣例 (convention)：
#   - name / email 進 ~/.env.profile（git-ignored；git 原生認 GIT_AUTHOR_*）
#   - token 已是變數引用 ($TIKTOK_API_KEY 等，存於 ~/.bash_local)，wizard 不碰
# ============================================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
DIM='\033[2m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="${REPO_ROOT}/scripts"
ENV_PROFILE="${HOME}/.env.profile"

# 共用環境變數 (REPO_DIR / OS / ARCH ...)；Step 2/3 的子腳本會自行再 source。
source "${SCRIPTS_DIR}/settings.sh"

header() { echo -e "\n${BLUE}==== $1 ====${NC}"; }
ok()     { echo -e "${GREEN}✔ $1${NC}"; }
skip()   { echo -e "${DIM}– $1${NC}"; }

# ask_default <prompt> <default>  -> echoes user input (or default on empty)
ask_default() {
    local prompt="$1" def="$2" ans
    # bash 3.2 (macOS 內建) 不支援 read -i；改以空輸入 fallback 至預設值
    read -r -p "$(echo -e "${YELLOW}${prompt}${NC} [${def}]: ")" ans
    echo "${ans:-$def}"
}

# confirm <prompt>  -> 0 if yes, 1 otherwise (default No)
confirm() {
    local ans
    read -r -p "$(echo -e "${YELLOW}$1${NC} [y/N]: ")" ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# ----------------------------------------------------------------------------
# Step 1 · 個人資訊 (Personal Info)
# ----------------------------------------------------------------------------
step_personal_info() {
    header "Step 1 · 個人資訊 (Personal Info)"

    # 以現有值為預設：先看 env、再看 git config
    local cur_name cur_email
    cur_name="${GIT_AUTHOR_NAME:-$(git config --global user.name 2>/dev/null || echo '')}"
    cur_email="${GIT_AUTHOR_EMAIL:-$(git config --global user.email 2>/dev/null || echo '')}"

    local git_name git_email
    git_name="$(ask_default '  使用者名稱 (name) ' "$cur_name")"
    git_email="$(ask_default '  電子郵件 (email)  ' "$cur_email")"

    cat >"$ENV_PROFILE" <<EOF
# ~/.env.profile — PII profile for this home user (git-ignored, written by setup.sh)
# 單一使用者：一組 name/email 為唯一來源；下方 git 變數由它衍生（git 原生讀取，
# commit 身分不需改動 tracked .gitconfig）。
export GIT_NAME="${git_name}"
export GIT_EMAIL="${git_email}"
export GIT_AUTHOR_NAME="\$GIT_NAME"    GIT_COMMITTER_NAME="\$GIT_NAME"
export GIT_AUTHOR_EMAIL="\$GIT_EMAIL"  GIT_COMMITTER_EMAIL="\$GIT_EMAIL"
EOF
    ok "已寫入 ${ENV_PROFILE}（下次開啟終端機或 source 後生效）"
    skip "token 為變數引用 (\$TIKTOK_API_KEY 等)，維持原位於 ~/.bash_local，wizard 不變更"
}

# ----------------------------------------------------------------------------
# Step 2 · Bash Env
# ----------------------------------------------------------------------------
step_bash_env() {
    header "Step 2 · Bash Env (dotfile 軟連結)"
    if confirm '  執行 bash_env_setup.sh（safe_link dotfiles，會備份既有非 symlink 檔）?'; then
        "${SCRIPTS_DIR}/bash_env_setup.sh"
        ok "bash env 已套用"
    else
        skip "略過 bash env"
    fi
}

# ----------------------------------------------------------------------------
# Step 3 · 工具逐一安裝 (Tools, one by one)
# 自動列舉 scripts/ 下所有 installer；以下兩者排除（非工具安裝）：
#   settings.sh          — 僅供 source 的共用環境變數
#   bash_env_setup.sh    — 已由 Step 2 處理
TOOLS_EXCLUDE="settings.sh bash_env_setup.sh"

# tool_meta <file> -> 印出 "<友善名稱>|<偵測指令>|<os_tag>"
#   os_tag: darwin（僅 brew 路徑）/ linux（僅 apt-get 路徑）/ any（無 OS 專屬指令，兩者皆可）
# 判斷依據為腳本實際內容（brew vs apt-get），非檔名慣例——如 bash.sh／ctags_setup.sh
# 雖未以 _mac 命名，但實際只有 brew 安裝路徑，故標記為 darwin-only。
tool_meta() {
    case "$1" in
        brew.sh)               echo "Homebrew|brew|darwin" ;;
        bash.sh)               echo "bash (brew)|brew|darwin" ;;
        ctags_setup.sh)        echo "Exuberant ctags (brew)|ctags|darwin" ;;
        openssl_mac_setup.sh)  echo "OpenSSL (macOS)|openssl|darwin" ;;
        mac.sh)                echo "macOS 全套 bootstrap|brew|darwin" ;;
        git.sh)                echo "git (apt-get build)|git|linux" ;;
        webmin.sh)             echo "Webmin|webmin|linux" ;;
        openssl_setup.sh)      echo "OpenSSL (source build)|openssl|linux" ;;
        ubuntu.sh)             echo "Ubuntu 全套 bootstrap||linux" ;;
        go.sh)                 echo "Go toolchain|go|any" ;;
        nodejs.sh)             echo "Node.js (nvm)|node|any" ;;
        vim.sh)                echo "Vim + plugins|vim|any" ;;
        git-secret.sh)         echo "git-secret (source build)|git-secret|any" ;;
        *)                     echo "$1||any" ;;
    esac
}

step_tools() {
    header "Step 3 · 工具逐一安裝 (Tools, one by one) — 僅列出當前 OS (${OS}) 適用項目"
    local file base label probe os_tag meta
    for file in "${SCRIPTS_DIR}"/*.sh; do
        base="$(basename "$file")"
        case " $TOOLS_EXCLUDE " in *" $base "*) continue ;; esac

        meta="$(tool_meta "$base")"
        label="$(echo "$meta" | cut -d'|' -f1)"
        probe="$(echo "$meta" | cut -d'|' -f2)"
        os_tag="$(echo "$meta" | cut -d'|' -f3)"

        if [ "$os_tag" != "any" ] && [ "$os_tag" != "$OS" ]; then
            skip "${label}: 僅適用 ${os_tag}（當前 ${OS}），略過"
            continue
        fi

        if [ -n "$probe" ] && command -v "$probe" >/dev/null 2>&1; then
            skip "${label}: 已安裝 ($(command -v "$probe"))"
            confirm "    仍要重新執行 ${base}?" || continue
        fi

        if confirm "  安裝 ${label} (${base})?"; then
            if "$file"; then
                ok "${label} 完成"
            else
                echo -e "${YELLOW}⚠ ${label} 安裝失敗（exit $?），繼續下一項${NC}"
            fi
        else
            skip "略過 ${label}"
        fi
    done
}

# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
main() {
    echo -e "${BLUE}env_setup 安裝精靈 (setup wizard)${NC}"
    echo -e "${DIM}OS=${OS} ARCH=${ARCH} — 隨時可 Ctrl-C 中斷${NC}"
    step_personal_info
    step_bash_env
    step_tools
    header "完成 (Done)"
    ok "三步驟結束。重新開啟終端機或 'source ~/.bashrc' 以載入設定。"
}

main "$@"
