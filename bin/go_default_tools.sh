#!/usr/bin/env bash
# Install the default BizShuk Go CLIs at master. Re-runnable: each run
# reinstalls the latest master; a failed tool is reported and skipped.

set -euo pipefail

TOOLS=(
    bizshuk/pm2
    bizshuk/skills
    bizshuk/dux
    bizshuk/port
    bizshuk/sessiond
    bizshuk/autop
    bizshuk/auth
    bizshuk/proxy
    bizshuk/mdserver
    bizshuk/vdl
    bizshuk/gx
    bizshuk/img
    bizshuk/inf
)

command -v go >/dev/null || {
    printf 'go is required (run scripts/go.sh first)\n' >&2
    exit 1
}

failed=()
for tool in "${TOOLS[@]}"; do
    printf '==> go install github.com/%s@master\n' "$tool"
    if ! go install "github.com/${tool}@master"; then
        failed+=("$tool")
    fi
done

printf '\ninstalled %d/%d tools into %s\n' \
    "$(( ${#TOOLS[@]} - ${#failed[@]} ))" "${#TOOLS[@]}" \
    "$(go env GOBIN | grep . || printf '%s/bin' "$(go env GOPATH)")"
if (( ${#failed[@]} > 0 )); then
    printf 'failed: %s\n' "${failed[*]}" >&2
    exit 1
fi
