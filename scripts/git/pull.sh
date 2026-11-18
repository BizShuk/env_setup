#!/usr/bin/env bash
# Fast-forward pull latest master for every git repo at ~/projects/* and ~/projects/*/*.
# Skips repos that are not on master, have uncommitted tracked changes, or lack an upstream,
# so local work is never merged, rebased, or overwritten.
set -uo pipefail

ROOT="${1:-$HOME/projects}"
export GIT_TERMINAL_PROMPT=0
export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=10"

updated=0 current=0 skipped=0 failed=0

for dir in "$ROOT"/*/ "$ROOT"/*/*/; do
    dir="${dir%/}"
    [ -e "$dir/.git" ] || continue

    branch=$(git -C "$dir" symbolic-ref --short -q HEAD || echo "detached")
    if [ "$branch" != "master" ]; then
        echo "SKIP    $dir (branch: $branch)"; skipped=$((skipped + 1)); continue
    fi
    if ! git -C "$dir" rev-parse -q --verify '@{upstream}' >/dev/null; then
        echo "SKIP    $dir (no upstream)"; skipped=$((skipped + 1)); continue
    fi
    if [ -n "$(git -C "$dir" status --porcelain --untracked-files=no)" ]; then
        echo "SKIP    $dir (uncommitted changes)"; skipped=$((skipped + 1)); continue
    fi

    before=$(git -C "$dir" rev-parse HEAD)
    if ! out=$(git -C "$dir" pull --ff-only --quiet 2>&1); then
        echo "FAIL    $dir: ${out//$'\n'/ }"; failed=$((failed + 1)); continue
    fi
    after=$(git -C "$dir" rev-parse HEAD)

    if [ "$before" = "$after" ]; then
        current=$((current + 1))
    else
        echo "UPDATE  $dir ($(git -C "$dir" rev-list --count "$before..$after") commits)"
        updated=$((updated + 1))
    fi
done

echo "summary: updated=$updated up-to-date=$current skipped=$skipped failed=$failed"
[ "$failed" -eq 0 ]
