#!/bin/bash
set -e

# ============================================================================
# 色彩定義 (Color Definitions)
# 用於美化終端機輸出,提升可讀性
# ============================================================================
GREEN='\033[0;32m'  # 成功訊息 (Success)
BLUE='\033[0;34m'   # 資訊訊息 (Info)
NC='\033[0m'        # 重置色彩 (No Color - reset)

# ============================================================================
# 工具操作說明 (Tool Operation Description)
# 此腳本 (This script) 重新建立 config/ 目錄中的符號連結 (recreates
# symbolic links),將系統層級 (system-level) 與使用者層級 (user-level) 的
# 組態檔案 (configuration files) 集中管理於 env_setup 專案中,達到
# 設定統一化 (centralized config) 與版本控制友善 (VCS-friendly) 的目的。
# ============================================================================

# ============================================================================
# 輔助函式 (Helper Function)
# ============================================================================

# 連結 IDE 設定檔案 (Link IDE Configuration Files)
# 將 env_setup 託管的 bin/vscode/ 設定 (settings, keybindings, snippets) 套用
# 至指定的 IDE User 目錄,支援 VSCode 與 Antigravity IDE 兩種工具。
#
# 參數 (Argument):
#   $1 - IDE 的 User 目錄路徑 (path to the IDE's User directory)
link_ide_config() {
    local user_dir="$1"

    # 操作 1/5: 確保 User 目錄存在,若不存在則遞迴建立
    # (Ensure User directory exists; create recursively if missing)
    mkdir -p "$user_dir"

    # 操作 2/5: 連結 settings.json (editor preferences, formatting rules, etc.)
    ln -sf "${HOME}/projects/env_setup/bin/vscode/settings.json" \
           "$user_dir/settings.json"

    # 操作 3/5: 連結 keybindings.json (custom keyboard shortcuts)
    ln -sf "${HOME}/projects/env_setup/bin/vscode/keybindings.json" \
           "$user_dir/keybindings.json"

    # 操作 4/5: 移除舊的 snippets 目錄,避免與符號連結衝突
    # (Remove legacy snippets directory to avoid symlink conflict)
    rm -rf "$user_dir/snippets"

    # 操作 5/5: 連結 snippets 目錄 (code snippet templates)
    ln -sf "${HOME}/projects/env_setup/bin/vscode/snippets" \
           "$user_dir/snippets"
}

# ============================================================================
# 主要流程 (Main Workflow)
# ============================================================================

echo -e "${BLUE}Recreating symbolic links in config/ directory...${NC}"

# ---------------------------------------------------------------------------
# 步驟 1/4 (Step 1/4): 確保 config 目錄存在
# ---------------------------------------------------------------------------
# 在使用者家目錄下建立 env_setup 的 config 子目錄,作為所有組態檔案連結的
# 統一存放位置 (unified storage location)。
mkdir -p "${HOME}/projects/env_setup/config"

# ---------------------------------------------------------------------------
# 步驟 2/4 (Step 2/4): 連結全域系統組態 (Link Global System Configurations)
# ---------------------------------------------------------------------------
# 將作業系統層級 (/etc, /var) 的組態檔案以符號連結方式納入專案,
# 方便集中檢視 (centralized inspection) 與版本控制 (version control)。
echo -e "${GREEN}Linking global configurations...${NC}"

# 2.1  檔案系統掛載表 (File system mount table)
ln -sf "/etc/fstab" "./tmp/fstab"

# 2.2  使用者群組資料庫 (User group database)
ln -sf "/etc/group" "./tmp/group"

# 2.3  主機名稱設定 (Hostname configuration)
ln -sf "/etc/hostname" "./tmp/hostname"

# 2.4  主機名稱與 IP 對應表 (Host-to-IP mappings)
ln -sf "/etc/hosts" "./tmp/hosts"

# 2.5  系統時區檔案 (System timezone file)
ln -sf "/etc/localtime" "./tmp/localtime"

# 2.6  OpenSSL 設定檔 (OpenSSL configuration)
ln -sf "/etc/ssl/openssl.cnf" "./tmp/openssl.cnf"

# 2.7  使用者帳號資料庫 (User account database)
ln -sf "/etc/passwd" "./tmp/passwd"

# 2.8  核心參數設定 (Kernel parameter configuration)
ln -sf "/etc/sysctl.conf" "./tmp/sysctl.conf"

# 2.9  系統認證記錄檔 (Authentication log)
ln -sf "/var/log/auth.log" "./tmp/auth.log"

# 2.10 SSH 客戶端設定 (SSH client configuration)
ln -sf "/etc/ssh/ssh_config" "./tmp/ssh_config"

# ---------------------------------------------------------------------------
# 步驟 3/4 (Step 3/4): 連結使用者家目錄組態 (Link User Home Configurations)
# ---------------------------------------------------------------------------
# 將使用者層級 (~/) 的組態檔案以符號連結方式納入專案,讓專案能直接引用
# 使用者自訂設定 (例如 .ssh 金鑰、.vscode 設定等)。
echo -e "${GREEN}Linking user configurations...${NC}"

# 3.1  自訂 Bash 外掛目錄 (Custom Bash plugins directory)
ln -sf "${HOME}/.bash_plugin" "./tmp/.bash_plugin"

# 3.2  Colima 設定目錄 (Colima config - macOS 上的 Docker 替代方案)
ln -sf "${HOME}/.colima" "./tmp/.colima"

# 3.3  XDG 設定根目錄 (XDG Base Directory config)
ln -sf "${HOME}/.config" "./tmp/.config"

# 3.4  GNU Screen 設定檔 (GNU Screen configuration)
ln -sf "${HOME}/.screenrc" "./tmp/.screenrc"

# 3.5  SSH 金鑰與設定目錄 (SSH keys and configuration directory)
ln -sf "${HOME}/.ssh" "./tmp/.ssh"

# 3.6  VSCode 設定目錄 (VSCode configuration directory)
ln -sf "${HOME}/.vscode" "./tmp/.vscode"

# 3.7  自訂函式庫目錄 (Custom library directory)
ln -sf "${HOME}/lib" "./tmp/lib"

# ---------------------------------------------------------------------------
# 步驟 4/4 (Step 4/4): 設定 VSCode 與 Antigravity IDE
# ---------------------------------------------------------------------------
# 將 env_setup 託管的 bin/vscode/ 設定套用至 IDE,確保 macOS 與 Linux 上
# 編輯器體驗一致 (consistent editor experience across platforms)。
echo -e "${BLUE}Configuring VSCode settings...${NC}"

# 4.1 依作業系統分支處理 (Branch by operating system)
if [ "$(uname)" = "Darwin" ]; then
    # 4.1.1 macOS 路徑: ~/Library/Application Support/

    # 設定 VSCode (Configure VSCode)
    link_ide_config "${HOME}/Library/Application Support/Code/User"

    # 設定 Antigravity IDE (Configure Antigravity IDE)
    link_ide_config "${HOME}/Library/Application Support/Antigravity IDE/User"
elif [ "$(uname)" = "Linux" ]; then
    # 4.1.2 Linux 路徑: XDG 標準 ~/.config/

    # 設定 VSCode (Configure VSCode)
    link_ide_config "${HOME}/.config/Code/User"

    # 設定 Antigravity IDE (Configure Antigravity IDE)
    link_ide_config "${HOME}/.config/Antigravity IDE/User"
fi

echo -e "${GREEN}All symbolic links have been recreated successfully!${NC}"
