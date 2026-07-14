#!/usr/bin/env bash
# uninstall_codex.sh - remove OpenAI Codex desktop app, CLI, and per-user data
#
# Scope (defaults to current user only):
#   - /Applications/Codex.app
#   - ~/.local/bin/codex
#   - ~/.codex
#   - ~/Library/{Application Support,Caches,Saved Application State,Containers,
#                 Logs,Preferences,LaunchAgents}/Codex* or com.openai.codex*
#   - /Library/{LaunchAgents,LaunchDaemons}/com.openai.codex*
#   - CodexBar.app (opt-in via --with-codexbar)
#
# Usage:
#   ./uninstall_codex.sh [--dry-run] [--with-codexbar] [--purge-system]
#
# Flags:
#   --dry-run       Print actions without deleting anything
#   --with-codexbar Also remove /Applications/CodexBar.app
#   --purge-system  Also remove /etc/codex and /Library/{LaunchAgents,LaunchDaemons}
#                   (requires sudo; will prompt once)
#
# Exit codes:
#   0  clean
#   1  user aborted
#   2  missing dependency

set -euo pipefail

DRY_RUN=0
WITH_CODEXBAR=0
PURGE_SYSTEM=0

for arg in "$@"; do
  case "$arg" in
    --dry-run)       DRY_RUN=1 ;;
    --with-codexbar) WITH_CODEXBAR=1 ;;
    --purge-system)  PURGE_SYSTEM=1 ;;
    -h|--help)
      sed -n '2,22p' "$0"; exit 0 ;;
    *)
      echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

log()  { printf '[uninstall] %s
' "$*"; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then echo "+ $*"; else eval "$@"; fi; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 2; }; }

need rm
need osascript

# 1. try to quit the app, ignore errors
log "attempting to quit Codex.app"
osascript -e 'quit app "Codex"' >/dev/null 2>&1 || true

# 2. collect targets
USER_PATHS=(
  "/Applications/Codex.app"
  "$HOME/.local/bin/codex"
  "$HOME/.codex"
)

USER_LIB_DIRS=(
  "$HOME/Library/Application Support/Codex"
  "$HOME/Library/Caches/Codex"
  "$HOME/Library/Saved Application State/com.openai.codex.savedState"
  "$HOME/Library/Logs/Codex"
)

USER_LIB_GLOBS=(
  "$HOME/Library/Caches/com.openai.codex*"
  "$HOME/Library/Saved Application State/com.openai.codex*"
  "$HOME/Library/Containers/com.openai.codex*"
  "$HOME/Library/Preferences/com.openai.codex*"
  "$HOME/Library/LaunchAgents/com.openai.codex*"
)

SYSTEM_PATHS=(
  "/Library/LaunchAgents/com.openai.codex*"
  "/Library/LaunchDaemons/com.openai.codex*"
  "/etc/codex"
)

# 3. bootout any matching launchd entries
LABELS=$(launchctl list 2>/dev/null | awk '/com\.openai\.codex/ {print $3}' | sort -u || true)
if [ -n "${LABELS:-}" ]; then
  log "unloading launch agents: $LABELS"
  for label in $LABELS; do
    run "launchctl bootout gui/$(id -u)/$label"
  done
fi

# 4. remove targets
log "removing app + CLI + user data"
for p in "${USER_PATHS[@]}"; do
  if [ -e "$p" ]; then run "rm -rf -- \"$p\""; else log "skip (absent): $p"; fi
done

log "removing Library dirs"
for p in "${USER_LIB_DIRS[@]}"; do
  if [ -e "$p" ]; then run "rm -rf -- \"$p\""; else log "skip (absent): $p"; fi
done

log "removing Library globs"
for g in "${USER_LIB_GLOBS[@]}"; do
  matches=$(compgen -G "$g" || true)
  if [ -n "$matches" ]; then
    for m in $matches; do run "rm -rf -- \"$m\""; done
  else
    log "skip (absent): $g"
  fi
done

if [ "$WITH_CODEXBAR" -eq 1 ]; then
  if [ -e "/Applications/CodexBar.app" ]; then
    log "removing CodexBar.app (--with-codexbar)"
    run "rm -rf -- /Applications/CodexBar.app"
  fi
fi

if [ "$PURGE_SYSTEM" -eq 1 ]; then
  log "removing system-level Codex paths (sudo)"
  for p in "${SYSTEM_PATHS[@]}"; do
    if [ -e "$p" ]; then run "sudo rm -rf -- \"$p\""; else log "skip (absent): $p"; fi
  done
fi

# 5. verify
log "verification"
left=$(
  {
    ls -d /Applications/Codex.app 2>/dev/null
    ls -d "$HOME/.codex" 2>/dev/null
    ls -d "$HOME/Library/Application Support/Codex" 2>/dev/null
    ls -d "$HOME/Library/Caches/Codex" 2>/dev/null
    command -v codex 2>/dev/null && true
  } | sed 's/^/  /'
)
if [ -n "$left" ]; then
  echo "$left"
  log "some targets still present (see above)"
else
  log "clean: no Codex artifacts found"
fi

log "done"
