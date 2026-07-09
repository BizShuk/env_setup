#!/usr/bin/env bash

# Script to export macOS custom keyboard shortcuts.
# Two independent sources are captured:
#   1. App Shortcuts  -> NSUserKeyEquivalents (global + per-app)
#      (System Settings > Keyboard > Keyboard Shortcuts > App Shortcuts)
#   2. Symbolic Hotkeys -> com.apple.symbolichotkeys (system-level:
#      Spotlight, screenshots, Mission Control, etc.)
#
# Restore the exported files with: bin/mac/mac_keyboard_shortcuts_restore.sh

set -euo pipefail

EXPORT_DIR="${HOME}/projects/env_setup/bin/mac/keyboard_shortcuts"
APP_DIR="${EXPORT_DIR}/app"
MANIFEST="${EXPORT_DIR}/manifest.txt"

mkdir -p "${APP_DIR}"
: > "${MANIFEST}"

echo "Exporting macOS keyboard shortcuts to: ${EXPORT_DIR}"
echo ""

# --- 1. Symbolic Hotkeys (whole domain, self-contained) ---------------------
if defaults read com.apple.symbolichotkeys >/dev/null 2>&1; then
    defaults export com.apple.symbolichotkeys "${EXPORT_DIR}/symbolichotkeys.plist"
    echo "✅ Symbolic Hotkeys      -> symbolichotkeys.plist"
else
    rm -f "${EXPORT_DIR}/symbolichotkeys.plist"
    echo "ℹ️  Symbolic Hotkeys      -> none found, skipped"
fi

# --- 2. Global App Shortcuts (NSGlobalDomain / "All Applications") ----------
if defaults read -g NSUserKeyEquivalents >/dev/null 2>&1; then
    defaults export -g - | plutil -extract NSUserKeyEquivalents xml1 -o "${EXPORT_DIR}/global.plist" -
    echo "✅ Global App Shortcuts   -> global.plist"
else
    rm -f "${EXPORT_DIR}/global.plist"
    echo "ℹ️  Global App Shortcuts   -> none found, skipped"
fi

# --- 3. Per-app App Shortcuts ----------------------------------------------
# Scan every preference domain for an NSUserKeyEquivalents key and snapshot it.
echo ""
echo "Scanning per-app shortcuts..."
app_count=0
for plist in "${HOME}/Library/Preferences/"*.plist; do
    [ -e "${plist}" ] || continue
    domain="$(basename "${plist}" .plist)"

    # Skip the global domain (handled above); it is stored as .GlobalPreferences.
    case "${domain}" in
        .GlobalPreferences|.GlobalPreferences.*) continue ;;
    esac

    if defaults read "${domain}" NSUserKeyEquivalents >/dev/null 2>&1; then
        defaults export "${domain}" - \
            | plutil -extract NSUserKeyEquivalents xml1 -o "${APP_DIR}/${domain}.plist" -
        echo "${domain}" >> "${MANIFEST}"
        echo "   ✅ ${domain}"
        app_count=$((app_count + 1))
    fi
done

# Drop empty per-app dir / manifest to keep the export tidy.
if [ "${app_count}" -eq 0 ]; then
    rm -f "${MANIFEST}"
    rmdir "${APP_DIR}" 2>/dev/null || true
fi

echo ""
echo "✅ Done. Captured ${app_count} per-app shortcut set(s)."
echo ""
echo "To restore on another machine (or after a reset), run:"
echo "  bin/mac/mac_keyboard_shortcuts_restore.sh"
