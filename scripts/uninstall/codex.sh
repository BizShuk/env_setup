#!/bin/bash
# codex.sh: Preview or remove Codex desktop app, CLI, user data, and launchd services
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [ -f "${REPO_DIR}/bin/bash/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${REPO_DIR}/bin/bash/settings.sh"
fi
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Validate operating system
if [ "$(uname -s)" != "Darwin" ]; then
    echo "Notice: Codex uninstall is supported only on macOS (Darwin). Current OS: $(uname -s). Skipping."
    exit 0
fi

print_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

預覽或移除 Codex 桌面應用程式、CLI、使用者資料與 Launchd 服務。
預設為預覽模式 (Preview / Dry-run)，不變更任何系統狀態。

Options:
  --apply          執行實際移除 (每個可用目標均需確認)
  --yes, -y        自動確認移除所有可用目標 (跳過 [y/N] 提示)
  --dry-run, -n    預覽待移除目標與預估大小 (預設行為)
  --with-codexbar  將 CodexBar.app 及相關資料納入掃描與移除範圍
  --purge-system   將系統層級 (/Library, /etc) 的 Codex 元件納入掃描與移除範圍 (需 root/sudo)
  --help, -h       顯示此說明訊息

Examples:
  $(basename "$0")                     # 預覽本機 Codex 元件與大小
  $(basename "$0") --with-codexbar     # 包含 CodexBar 進行預覽
  $(basename "$0") --apply             # 逐項確認後移除
  $(basename "$0") --apply --yes       # 免確認直接移除所有本機 Codex 元件
EOF
}

APPLY=false
YES=false
DRY_RUN=false
WITH_CODEXBAR=false
PURGE_SYSTEM=false

while [ $# -gt 0 ]; do
    case "$1" in
        --apply)
            APPLY=true
            shift
            ;;
        --yes|-y)
            YES=true
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            APPLY=false
            shift
            ;;
        --with-codexbar)
            WITH_CODEXBAR=true
            shift
            ;;
        --purge-system)
            PURGE_SYSTEM=true
            shift
            ;;
        --help|-h)
            print_help
            exit 0
            ;;
        *)
            echo "Error: 未知引數 '$1'" >&2
            print_help >&2
            exit 1
            ;;
    esac
done

if [ "${DRY_RUN}" = true ]; then
    APPLY=false
fi

ITEM_IDS=()
ITEM_SCOPES=()
ITEM_TARGETS=()
ITEM_DESCS=()
ITEM_KINDS=()
ITEM_AVAILS=()
ITEM_SIZES=()
ITEM_KBS=()

SEEN_TARGETS=()

is_seen() {
    local target="$1"
    if [ "${#SEEN_TARGETS[@]}" -eq 0 ]; then
        return 1
    fi
    local s
    for s in "${SEEN_TARGETS[@]}"; do
        if [ "${s}" = "${target}" ]; then
            return 0
        fi
    done
    return 1
}

get_path_size() {
    local target="$1"
    if [ ! -e "${target}" ] && [ ! -L "${target}" ]; then
        echo "0 B"
        return 0
    fi
    local size
    size=$(du -sh "${target}" 2>/dev/null | awk '{print $1}' || true)
    if [ -z "${size}" ]; then
        echo "N/A"
    else
        echo "${size}"
    fi
}

get_path_kb() {
    local target="$1"
    if [ ! -e "${target}" ] && [ ! -L "${target}" ]; then
        echo "0"
        return 0
    fi
    local kb
    kb=$(du -sk "${target}" 2>/dev/null | awk '{print $1}' || true)
    if [ -z "${kb}" ]; then
        echo "0"
    else
        echo "${kb}"
    fi
}

format_kb() {
    local kb="$1"
    if [ -z "${kb}" ] || [ "${kb}" -le 0 ]; then
        echo "0 B"
    elif [ "${kb}" -ge 1048576 ]; then
        awk -v k="${kb}" 'BEGIN {printf "%.1f GiB", k/1048576}'
    elif [ "${kb}" -ge 1024 ]; then
        awk -v k="${kb}" 'BEGIN {printf "%.1f MiB", k/1024}'
    else
        echo "${kb} KiB"
    fi
}

find_matching_paths() {
    local full_pattern="$1"
    local dir
    dir="$(dirname "${full_pattern}")"
    local base
    base="$(basename "${full_pattern}")"
    [ ! -d "${dir}" ] && return 0
    local prev_nullglob
    prev_nullglob=$(shopt -p nullglob || true)
    shopt -s nullglob
    # shellcheck disable=SC2206
    local matches=("${dir}"/${base})
    eval "${prev_nullglob}"
    if [ "${#matches[@]}" -gt 0 ]; then
        for m in "${matches[@]}"; do
            if [ -e "${m}" ] || [ -L "${m}" ]; then
                echo "${m}"
            fi
        done
    fi
}

register_item() {
    local id="$1"
    local scope="$2"
    local target="$3"
    local desc="$4"
    local kind="$5"
    local avail="$6"
    local size="$7"
    local kb="$8"

    ITEM_IDS+=("${id}")
    ITEM_SCOPES+=("${scope}")
    ITEM_TARGETS+=("${target}")
    ITEM_DESCS+=("${desc}")
    ITEM_KINDS+=("${kind}")
    ITEM_AVAILS+=("${avail}")
    ITEM_SIZES+=("${size}")
    ITEM_KBS+=("${kb}")
}

add_path_selector() {
    local id="$1"
    local scope="$2"
    local target="$3"
    local desc="$4"
    local kind="$5"

    if is_seen "${target}"; then
        return 0
    fi
    SEEN_TARGETS+=("${target}")

    local effective_kind="${kind}"
    if [ -e "${target}" ] || [ -L "${target}" ]; then
        if [ "${kind}" = "path" ] && [ ! -w "${target}" ]; then
            effective_kind="root-path"
        fi
        local size kb
        size=$(get_path_size "${target}")
        kb=$(get_path_kb "${target}")
        register_item "${id}" "${scope}" "${target}" "${desc}" "${effective_kind}" true "${size}" "${kb}"
    else
        register_item "${id}" "${scope}" "${target}" "${desc}" "${effective_kind}" false "0 B" 0
    fi
}

add_glob_selector() {
    local id="$1"
    local scope="$2"
    local pattern="$3"
    local desc="$4"
    local kind="$5"

    local raw_matches=()
    while IFS= read -r match || [ -n "${match}" ]; do
        [ -n "${match}" ] && raw_matches+=("${match}")
    done < <(find_matching_paths "${pattern}")

    local fresh_matches=()
    if [ "${#raw_matches[@]}" -gt 0 ]; then
        for m in "${raw_matches[@]}"; do
            if ! is_seen "${m}"; then
                fresh_matches+=("${m}")
            fi
        done
    fi

    local count="${#fresh_matches[@]}"
    if [ "${count}" -eq 0 ]; then
        if ! is_seen "${pattern}"; then
            SEEN_TARGETS+=("${pattern}")
            register_item "${id}" "${scope}" "${pattern}" "${desc}" "${kind}" false "0 B" 0
        fi
    elif [ "${count}" -eq 1 ]; then
        local target="${fresh_matches[0]}"
        SEEN_TARGETS+=("${target}")
        local effective_kind="${kind}"
        if [ "${kind}" = "path" ] && [ ! -w "${target}" ]; then
            effective_kind="root-path"
        fi
        local size kb
        size=$(get_path_size "${target}")
        kb=$(get_path_kb "${target}")
        register_item "${id}" "${scope}" "${target}" "${desc}" "${effective_kind}" true "${size}" "${kb}"
    else
        local idx=1
        for target in "${fresh_matches[@]}"; do
            SEEN_TARGETS+=("${target}")
            local effective_kind="${kind}"
            if [ "${kind}" = "path" ] && [ ! -w "${target}" ]; then
                effective_kind="root-path"
            fi
            local size kb
            size=$(get_path_size "${target}")
            kb=$(get_path_kb "${target}")
            register_item "${id}-${idx}" "${scope}" "${target}" "${desc}" "${effective_kind}" true "${size}" "${kb}"
            idx=$((idx + 1))
        done
    fi
}

collect_launchd_services() {
    if ! command -v launchctl >/dev/null 2>&1; then
        return 0
    fi
    local labels
    labels=$(launchctl list 2>/dev/null | awk '{print $3}' | grep -E '^(com\.openai\.codex|com\.codex)' || true)
    if [ -n "${labels}" ]; then
        local raw_labels=()
        while IFS= read -r l || [ -n "${l}" ]; do
            [ -n "${l}" ] && raw_labels+=("${l}")
        done <<< "${labels}"

        local count="${#raw_labels[@]}"
        if [ "${count}" -eq 1 ]; then
            local label="${raw_labels[0]}"
            SEEN_TARGETS+=("${label}")
            register_item "launch-agent" "user-launchd" "${label}" "Unload Codex user launchd service" "launchd-service" true "-" 0
        elif [ "${count}" -gt 1 ]; then
            local idx=1
            for label in "${raw_labels[@]}"; do
                SEEN_TARGETS+=("${label}")
                register_item "launch-agent-${idx}" "user-launchd" "${label}" "Unload Codex user launchd service" "launchd-service" true "-" 0
                idx=$((idx + 1))
            done
        fi
    fi
}

collect_all_targets() {
    # 1. Active launchd services
    collect_launchd_services

    # 2. Codex App bundles
    add_path_selector "codex-app" "user" "/Applications/Codex.app" "Remove Codex desktop app in /Applications" "path"
    add_path_selector "codex-app-user" "user" "${HOME}/Applications/Codex.app" "Remove user Codex desktop app in ~/Applications" "path"

    # 3. Codex CLI binaries
    add_path_selector "codex-cli" "user" "${HOME}/.local/bin/codex" "Remove per-user Codex CLI" "path"
    add_path_selector "codex-cli-sys" "user" "/usr/local/bin/codex" "Remove /usr/local Codex CLI" "path"

    # 4. Codex User Configuration & Data
    add_path_selector "codex-home" "user" "${HOME}/.codex" "Remove Codex configuration and per-user data" "path"
    add_path_selector "app-support" "user" "${HOME}/Library/Application Support/Codex" "Remove Codex Application Support data" "path"
    add_path_selector "cache" "user" "${HOME}/Library/Caches/Codex" "Remove Codex cache" "path"
    add_path_selector "cache-openai" "user" "${HOME}/Library/Caches/com.openai.codex" "Remove com.openai.codex cache" "path"
    add_glob_selector "bundle-cache" "user" "${HOME}/Library/Caches/com.openai.codex*" "Remove Codex bundle caches" "path"
    add_path_selector "preference" "user" "${HOME}/Library/Preferences/com.openai.codex.plist" "Remove Codex preference plist" "path"
    add_glob_selector "bundle-preference" "user" "${HOME}/Library/Preferences/com.openai.codex*" "Remove Codex preference files" "path"
    add_path_selector "saved-state" "user" "${HOME}/Library/Saved Application State/com.openai.codex.savedState" "Remove Codex saved application state" "path"
    add_glob_selector "bundle-saved-state" "user" "${HOME}/Library/Saved Application State/com.openai.codex*" "Remove Codex bundle saved states" "path"
    add_glob_selector "container" "user" "${HOME}/Library/Containers/com.openai.codex*" "Remove Codex sandbox containers" "path"
    add_path_selector "logs" "user" "${HOME}/Library/Logs/Codex" "Remove Codex logs" "path"

    # 5. LaunchAgent plist files
    add_glob_selector "launch-agent-file" "user" "${HOME}/Library/LaunchAgents/com.openai.codex*.plist" "Remove Codex user LaunchAgent files" "path"
    add_glob_selector "launch-agent-file-alt" "user" "${HOME}/Library/LaunchAgents/com.codex*.plist" "Remove Codex user LaunchAgent files" "path"

    # 6. Optional: CodexBar scope
    if [ "${WITH_CODEXBAR}" = true ]; then
        add_path_selector "codexbar-app" "user" "/Applications/CodexBar.app" "Remove CodexBar desktop app in /Applications" "path"
        add_path_selector "codexbar-app-user" "user" "${HOME}/Applications/CodexBar.app" "Remove user CodexBar desktop app in ~/Applications" "path"
        add_path_selector "codexbar-app-support" "user" "${HOME}/Library/Application Support/CodexBar" "Remove CodexBar Application Support data" "path"
    fi

    # 7. Optional: System purge scope
    if [ "${PURGE_SYSTEM}" = true ]; then
        add_path_selector "system-app-support" "system" "/Library/Application Support/Codex" "Remove system Codex Application Support data" "root-path"
        add_path_selector "system-preference" "system" "/Library/Preferences/com.openai.codex.plist" "Remove system Codex preference plist" "root-path"
        add_glob_selector "system-bundle-pref" "system" "/Library/Preferences/com.openai.codex*" "Remove system Codex preferences" "root-path"
        add_glob_selector "system-launch-agent" "system" "/Library/LaunchAgents/com.openai.codex*.plist" "Remove system Codex LaunchAgent files" "root-path"
        add_glob_selector "system-launch-daemon" "system" "/Library/LaunchDaemons/com.openai.codex*.plist" "Remove system Codex LaunchDaemon files" "root-path"
        add_path_selector "system-etc" "system" "/etc/codex" "Remove system Codex configuration" "root-path"
    fi
}

print_targets_table() {
    printf "%-22s %-14s %-10s %-10s %-55s %s\n" "ID" "SCOPE" "STATUS" "SIZE" "TARGET" "DESCRIPTION"
    printf "%-22s %-14s %-10s %-10s %-55s %s\n" "----------------------" "--------------" "----------" "----------" "-------------------------------------------------------" "-----------------------------------------"

    for i in "${!ITEM_IDS[@]}"; do
        local id="${ITEM_IDS[$i]}"
        local scope="${ITEM_SCOPES[$i]}"
        local target="${ITEM_TARGETS[$i]}"
        local desc="${ITEM_DESCS[$i]}"
        local avail="${ITEM_AVAILS[$i]}"
        local size="${ITEM_SIZES[$i]}"
        local status="ready"
        if [ "${avail}" != true ]; then
            status="not found"
        fi
        printf "%-22s %-14s %-10s %-10s %-55s %s\n" "${id}" "${scope}" "${status}" "${size}" "${target}" "${desc}"
    done
}

ensure_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        if ! command -v sudo >/dev/null 2>&1; then
            echo "Error: 系統層級移除需要 root 權限，但找不到 sudo 指令。" >&2
            exit 1
        fi
        if ! sudo -n true 2>/dev/null; then
            echo "提示: 系統層級移除需要 sudo 權限，請輸入密碼："
            sudo -v
        fi
    fi
}

unload_confirmed_launchd() {
    local uid
    uid="$(id -u)"
    for idx in "${CONFIRMED_INDICES[@]}"; do
        local kind="${ITEM_KINDS[$idx]}"
        local target="${ITEM_TARGETS[$idx]}"
        if [ "${kind}" = "launchd-service" ]; then
            if command -v launchctl >/dev/null 2>&1; then
                launchctl bootout "gui/${uid}/${target}" 2>/dev/null || \
                launchctl unload 2>/dev/null || true
            fi
        elif [[ "${target}" == *"LaunchAgents"* ]] || [[ "${target}" == *"LaunchDaemons"* ]]; then
            if [ "${kind}" = "root-path" ]; then
                sudo launchctl bootout system "${target}" 2>/dev/null || \
                sudo launchctl unload "${target}" 2>/dev/null || true
            else
                launchctl bootout "gui/${uid}" "${target}" 2>/dev/null || \
                launchctl unload "${target}" 2>/dev/null || true
            fi
        fi
    done
}

terminate_codex_processes() {
    local my_pid="$$"
    local pids
    pids=$(pgrep -f "Codex" 2>/dev/null | grep -v "^${my_pid}$" || true)
    if [ -n "${pids}" ]; then
        echo "正在終止運行中的 Codex 行程..."
        if command -v osascript >/dev/null 2>&1; then
            osascript -e 'quit app "Codex"' 2>/dev/null || true
            sleep 0.5
        fi
        pids=$(pgrep -f "Codex" 2>/dev/null | grep -v "^${my_pid}$" || true)
        if [ -n "${pids}" ]; then
            pkill -f "Codex" 2>/dev/null || true
            sleep 0.3
        fi
        pids=$(pgrep -f "Codex" 2>/dev/null | grep -v "^${my_pid}$" || true)
        if [ -n "${pids}" ]; then
            for pid in ${pids}; do
                if [ "${pid}" != "${my_pid}" ]; then
                    kill -9 "${pid}" 2>/dev/null || true
                fi
            done
        fi
        echo "  ✓ 已終止 Codex 行程"
    fi
}

collect_all_targets

total_kb=0
available_count=0
for i in "${!ITEM_IDS[@]}"; do
    if [ "${ITEM_AVAILS[$i]}" = true ]; then
        available_count=$((available_count + 1))
        total_kb=$((total_kb + ITEM_KBS[i]))
    fi
done

if [ "${APPLY}" != true ]; then
    echo "================================================================================================================="
    echo " [Preview Mode] Codex Uninstall 目標預覽 (Dry-run)"
    echo "================================================================================================================="
    print_targets_table
    echo "-----------------------------------------------------------------------------------------------------------------"
    total_formatted=$(format_kb "${total_kb}")
    echo "Summary：發現 ${available_count} 個可用目標 (預估大小: ${total_formatted})。"
    echo ""
    apply_cmd="$(basename "$0") --apply"
    if [ "${WITH_CODEXBAR}" = true ]; then
        apply_cmd="${apply_cmd} --with-codexbar"
    fi
    if [ "${PURGE_SYSTEM}" = true ]; then
        apply_cmd="${apply_cmd} --purge-system"
    fi
    echo "Preview mode：未修改任何 Codex artifact。實際執行請使用 \`${apply_cmd}\`。"
    echo "================================================================================================================="
    exit 0
fi

echo "================================================================================================================="
echo " [Apply Mode] 執行 Codex 移除"
echo "================================================================================================================="
print_targets_table
echo "-----------------------------------------------------------------------------------------------------------------"

if [ "${available_count}" -eq 0 ]; then
    echo "Apply mode：未發現任何已安裝或殘留的 Codex 元件。"
    echo ""
    echo "Summary：applied=0 skipped=0 failed=0"
    exit 0
fi

CONFIRMED_INDICES=()
skipped=0
applied=0
failed=0

needs_root=false
for i in "${!ITEM_IDS[@]}"; do
    if [ "${ITEM_AVAILS[$i]}" = true ] && [ "${ITEM_KINDS[$i]}" = "root-path" ]; then
        needs_root=true
        break
    fi
done

if [ "${needs_root}" = true ]; then
    ensure_sudo
fi

if [ "${YES}" = true ]; then
    for i in "${!ITEM_IDS[@]}"; do
        if [ "${ITEM_AVAILS[$i]}" = true ]; then
            CONFIRMED_INDICES+=("${i}")
        fi
    done
else
    echo ""
    echo "Apply mode：每個 available target 都必須個別確認，預設為 No。"
    for i in "${!ITEM_IDS[@]}"; do
        if [ "${ITEM_AVAILS[$i]}" != true ]; then
            continue
        fi
        target="${ITEM_TARGETS[$i]}"
        scope="${ITEM_SCOPES[$i]}"
        desc="${ITEM_DESCS[$i]}"
        id="${ITEM_IDS[$i]}"

        printf "移除 %s（%s）— %s？ [y/N] " "${target}" "${scope}" "${desc}"
        if ! read -r answer; then
            echo ""
            answer="n"
        elif [ ! -t 0 ]; then
            echo "${answer}"
        fi
        case "${answer}" in
            [yY]|[yY][eE][sS])
                CONFIRMED_INDICES+=("${i}")
                ;;
            *)
                echo "  - skipped ${id}"
                skipped=$((skipped + 1))
                ;;
        esac
    done
fi

if [ "${#CONFIRMED_INDICES[@]}" -eq 0 ]; then
    echo ""
    echo "Summary：applied=0 skipped=${skipped} failed=0"
    exit 0
fi

# 1. Unload launchd agents first
unload_confirmed_launchd

# 2. Terminate running processes
terminate_codex_processes

# 3. Safely remove the confirmed paths
for idx in "${CONFIRMED_INDICES[@]}"; do
    id="${ITEM_IDS[$idx]}"
    kind="${ITEM_KINDS[$idx]}"
    target="${ITEM_TARGETS[$idx]}"

    if [ "${kind}" = "launchd-service" ]; then
        echo "  ✓ applied ${id}"
        applied=$((applied + 1))
        continue
    fi

    if [ "${kind}" = "root-path" ]; then
        if sudo rm -rf -- "${target}"; then
            echo "  ✓ applied ${id}"
            applied=$((applied + 1))
        else
            echo "  ✗ failed ${id}：無法以 root 權限移除 ${target}" >&2
            failed=$((failed + 1))
        fi
    else
        if rm -rf -- "${target}"; then
            echo "  ✓ applied ${id}"
            applied=$((applied + 1))
        else
            echo "  ✗ failed ${id}：無法移除 ${target}" >&2
            failed=$((failed + 1))
        fi
    fi
done

echo ""
echo "Summary：applied=${applied} skipped=${skipped} failed=${failed}"
if [ "${failed}" -gt 0 ]; then
    exit 1
fi
