#!/bin/bash
# ============================================================================
# _lib_bash_plugin.sh — Idempotent block updater for ~/.bash_plugin
# ============================================================================
# Provides update_bash_plugin_block to replace configurations atomically by marker,
# preventing duplicate environment variable exports across re-runs.
#
# Usage:
#   source "$(dirname "$0")/_lib_bash_plugin.sh"
#   update_bash_plugin_block "<component>" [legacy_sed_patterns...] <<'EOF'
#   export FOO=bar
#   EOF
# ============================================================================

update_bash_plugin_block() {
    local component="$1"
    shift
    local target="${BASH_PLUGIN:-${INSTALL_DIR:-$HOME}/.bash_plugin}"
    local begin_marker="# >>> env_setup ${component} >>>"
    local end_marker="# <<< env_setup ${component} <<<"

    [ -f "${target}" ] || touch "${target}"

    local content
    content="$(cat)"

    local tmp_file
    tmp_file="$(mktemp)"

    local sed_args=("-e" "/^${begin_marker}$/,/^${end_marker}$/d")
    for pattern in "$@"; do
        sed_args+=("-e" "${pattern}")
    done

    sed "${sed_args[@]}" "${target}" > "${tmp_file}"
    cat "${tmp_file}" > "${target}"
    rm -f "${tmp_file}"

    # Only append if content has non-whitespace characters
    if [ -n "${content//[[:space:]]/}" ]; then
        {
            echo ""
            echo "${begin_marker}"
            echo "${content}"
            echo "${end_marker}"
        } >> "${target}"
    fi
}
