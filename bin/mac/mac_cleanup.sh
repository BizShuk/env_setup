#!/bin/bash

# 環境變數入口 (Settings)
SCRIPT_DIR="${HOME}/projects/env_setup/bin"
# shellcheck source=../bash/settings.sh
. "$SCRIPT_DIR/bash/settings.sh"

confirm() {
    read -p "$1 [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

# Private
sudo rm -rf /private/var/log/*
sudo rm -rf /private/var/tmp/*
# /private/var/db, No
# /private/var/vm, No
# /private/var/folders # Application temporary cache, remove by restart computer.

# System Library
sudo rm -rf /Library/Logs/*
# Clear user cache:
rm -rf ~/Library/Caches/*
# Clear system cache:
sudo rm -rf /Library/Caches/*

# Remove old Time Machine backups:
sudo tmutil deletelocalsnapshots /

# Remove unused Docker images and containers:
# check whether cmd docker exists if so run the command
command -v docker >/dev/null 2>&1 && docker system prune -a

# Empty the Trash:
rm -rf ~/.Trash/*


# Lark
cleanup_lark() {
    local lark_dir="$HOME/Library/Application Support/LarkInternational"
    if [ ! -d "$lark_dir" ]; then
        return 0
    fi

    (
        cd "$lark_dir" || exit
        shopt -s nullglob

        # 定義顯示大小的輔助函式
        show_size() {
            local label="$1"
            shift
            if [ $# -gt 0 ]; then
                local size
                size=$(du -csh "$@" 2>/dev/null | tail -n 1 | cut -f 1)
                echo "  $label ($size)"
                # 列出具體路徑
                for p in "$@"; do
                    echo "    - $p"
                done
            fi
        }

        echo "=== Lark 清理評估 ==="
        show_size "1. 日誌 (Logs)" sdk_storage/log/xlog/*.alaudalog sdk_storage/log/native-pc-sdk/*.log sdk_storage/log/netlog/* sdk_storage/log/monitor/*.dmp
        show_size "2. 更新暫存 (Updates)" update/update_downloading update/update.noindex
        show_size "3. 搜尋索引與 Pipeline (Search Index & DB)" sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/search_v2_*.db* sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/pipeline.db
        show_size "4. 媒體與貼圖快取 (Avatars, Images & Stickers)" sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/resources/avatars/* sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/resources/images/* sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/resources/stickers/*
        show_size "5. GPU/Code 快取 (Caches)" ShaderCache/* GrShaderCache/* GraphiteDawnCache/* CodeCache/* iron/ShaderCache/* iron/GrShaderCache/* iron/GraphiteDawnCache/*
        echo "======================"

        if confirm "是否確認刪除上述 Lark 快取檔案？"; then
            echo "正在清理 Lark 檔案..."
            # 1. 日誌
            rm -rf sdk_storage/log/xlog/*.alaudalog
            rm -rf sdk_storage/log/native-pc-sdk/*.log
            rm -rf sdk_storage/log/netlog/*
            rm -rf sdk_storage/log/monitor/*.dmp

            # 2. 更新暫存
            rm -rf update/update_downloading update/update.noindex

            # 3. 搜尋索引 + Pipeline
            rm -f sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/search_v2_*.db*
            rm -f sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/pipeline.db

            # 4. 頭像 + 圖片 + 貼圖快取
            rm -rf sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/resources/avatars/*
            rm -rf sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/resources/images/*
            rm -rf sdk_storage/8f58e7b608ae3d17ece2f19469e37e1c/resources/stickers/*

            # 5. GPU/Code 快取
            rm -rf ShaderCache/* GrShaderCache/* GraphiteDawnCache/* CodeCache/*
            rm -rf iron/ShaderCache/* iron/GrShaderCache/* iron/GraphiteDawnCache/*
            echo "Lark 清理完成。"
        else
            echo "已取消 Lark 清理。"
        fi
    )
}

cleanup_lark

# Chrome Cache
rm -rf ~/Library/Caches/Google/Chrome/Default/Cache/Cache_Data

# Golang
rm -rf ~/projects/.local/go/src/*



# iMovie/iTunes
if confirm "Clean up ~/Music (delete all music and iMovie/iTunes media)?"; then
    rm -rf ~/Music/*
fi

# Whatapps
if confirm "Clean up WhatsApp Media cache?"; then
    rm -rf ~/Library/Group\ Containers/group.net.whatsapp.WhatsApp.shared/Message/Media/*
fi

# WeChat
if confirm "Clean up WeChat Data (deletes all chat history and local WeChat files)?"; then
    rm -rf ~/Library/Containers/com.tencent.xinWeChat/Data
    rm -rf ~/Library/Containers/com.tencent.xinWeChat.WeChatMacShare/Data
fi

# Podcast
rm -rf ~/Library/Containers/com.apple.podcasts/Data/tmp/StreamedMedia/*.mp3

# BackUp/Update
rm -rf ~/Library/iTunes/iPhone\ Software\ Updates/*
rm -rf ~/Library/Application\ Support/MobileSync/Backup/*

BREWFILE_PATH="${REPO_SCRIPTS}/Brewfile"
if [ -f "$BREWFILE_PATH" ]; then
    brew bundle cleanup --file="$BREWFILE_PATH" --force
else
    echo "Warning: Brewfile not found at $BREWFILE_PATH, skipping brew cleanup."
fi


reset () {
    if confirm "Reset Safari settings and delete Safari Bookmarks?"; then
        rm -Rf ~/Library/Caches/Apple\ -\ Safari\ -\ Safari\ Extensions\ Gallery
        rm -Rf ~/Library/Caches/Metadata/Safari
        rm -Rf ~/Library/Caches/com.apple.Safari
        rm -Rf ~/Library/Caches/com.apple.WebKit.PluginProcess
        rm -Rf ~/Library/Cookies/Cookies.binarycookies
        rm -Rf ~/Library/Preferences/Apple\ -\ Safari\ -\ Safari\ Extensions\ Gallery
        rm -Rf ~/Library/Preferences/com.apple.Safari.LSSharedFileList.plist
        rm -Rf ~/Library/Preferences/com.apple.Safari.RSS.plist
        rm -Rf ~/Library/Preferences/com.apple.Safari.plist
        rm -Rf ~/Library/Preferences/com.apple.WebFoundation.plist
        rm -Rf ~/Library/Preferences/com.apple.WebKit.PluginHost.plist
        rm -Rf ~/Library/Preferences/com.apple.WebKit.PluginProcess.plist
        rm -Rf ~/Library/PubSub/Database
        rm -Rf ~/Library/Saved\ Application\ State/com.apple.Safari.savedState
        rm ~/Library/Safari/Bookmarks.plist
    fi
}

runtimeCache() {
    brew cleanup --prune=all
    go clean -cache
    pip cache purge    
    if [ -d "$HOME/projects" ]; then
        echo "=== node_modules 清理評估 ==="
        local temp_file
        temp_file=$(mktemp)
        find "$HOME/projects" -name "node_modules" -type d -prune > "$temp_file"

        local count=0
        while IFS= read -r dir; do
            if [ -n "$dir" ]; then
                local size_str
                size_str=$(du -sh "$dir" 2>/dev/null | cut -f1)
                echo "  - $dir ($size_str)"
                count=$((count + 1))
            fi
        done < "$temp_file"

        if [ "$count" -gt 0 ]; then
            echo "=============================="
            if confirm "是否確認刪除上述共 $count 個 node_modules 目錄？"; then
                while IFS= read -r dir; do
                    if [ -n "$dir" ]; then
                        rm -rf "$dir"
                    fi
                done < "$temp_file"
                echo "node_modules 清理完成。"
            else
                echo "已取消 node_modules 清理。"
            fi
        else
            echo "未找到任何 node_modules 目錄。"
            echo "=============================="
        fi
        rm -f "$temp_file"
    fi

    rm -rf ~/.cache/uv/archive-v0/

    # 刪除 npx 快取 (Delete npx cache)
    rm -rf ~/.npm/_npx

    # 尋找所有 *venv* 資料夾並刪除，但排除 ~/.venv (Find and remove all *venv* folders except ~/.venv)
    find "$HOME" -mindepth 1 \
        \( -path "$HOME/.venv" \
        -o -path "$HOME/Library" \
        -o -path "$HOME/.Trash" \
        -o -path "$HOME/.cargo" \
        -o -path "$HOME/.rustup" \
        -o -path "$HOME/.npm" \
        -o -path "$HOME/.nvm" \
        -o -path "$HOME/.cache" \
        -o -path "$HOME/.local" \) -prune \
        -o -type d -name "*venv*" -prune -exec rm -rf '{}' +
}


remove_java() {
    if confirm "Uninstall all Java Virtual Machines and Java internet plugins?"; then
        echo "Uninstalling Java..."
        # Remove Java Virtual Machines
        sudo rm -rf /Library/Java/JavaVirtualMachines/*

        # Remove Java Internet Plug-Ins
        sudo rm -rf "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin"

        # Remove Java Preference Panes
        sudo rm -rf /Library/PreferencePanes/JavaControlPanel.prefPane

        # Remove Oracle Java Application Support
        sudo rm -rf "/Library/Application Support/Oracle/Java"
        rm -rf ~/Library/Application\ Support/Oracle/Java
    fi
}

# get options
while getopts "fj" opt; do
  case $opt in
    f)
        echo "Force cleanup enabled."
        reset
        remove_java
        ;;
    j)
        remove_java
        ;;
    \?) # 處理未知標籤
        echo "Unknown option: $opt"
        ;;
    :) # 如果標籤後漏掉數值
        echo "選項 -$OPTARG 遺漏了參數數值。 f:force clean, j:remove java" >&2
        exit 1
        ;;
  esac
done

# 執行執行期快取清理 (Execute runtime cache cleanup)
runtimeCache





