#!/usr/bin/env bash
# Install the default global skill sources via the `skills` CLI.
# Extra arguments are passed to every `skills add` call, e.g.
#   skills_default.sh --yes      # skip the TUI, install every detected skill

set -euo pipefail

SOURCES=(
    bizshuk/cc-plugin
    bizshuk/tools
    bizshuk/platform
    bizshuk/gosdk
    bizshuk/inf
    bizshuk/dux
)

command -v skills >/dev/null || {
    printf 'skills CLI is required (run go_default_tools.sh first)\n' >&2
    exit 1
}

failed=()
for source in "${SOURCES[@]}"; do
    printf '==> skills add %s\n' "$source"
    if ! skills add "$source" "$@"; then
        failed+=("$source")
    fi
done

printf '\ninstalled %d/%d skill sources\n' \
    "$(( ${#SOURCES[@]} - ${#failed[@]} ))" "${#SOURCES[@]}"
if (( ${#failed[@]} > 0 )); then
    printf 'failed: %s\n' "${failed[*]}" >&2
    exit 1
fi
