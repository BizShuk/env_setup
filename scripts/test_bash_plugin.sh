#!/bin/bash
set -euo pipefail

# ============================================================================
# test_bash_plugin.sh — Unit tests for _lib_bash_plugin.sh
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_lib_bash_plugin.sh
source "${SCRIPT_DIR}/_lib_bash_plugin.sh"

TEST_TMP="$(mktemp -d)"
trap 'rm -rf "${TEST_TMP}"' EXIT

export BASH_PLUGIN="${TEST_TMP}/.bash_plugin"

echo "Running test: block creation..."
update_bash_plugin_block "foo" <<'EOF'
export FOO=1
EOF

if ! grep -q "# >>> env_setup foo >>>" "${BASH_PLUGIN}"; then
    echo "FAIL: begin marker not found" >&2
    exit 1
fi
if ! grep -q "export FOO=1" "${BASH_PLUGIN}"; then
    echo "FAIL: content not found" >&2
    exit 1
fi
if ! grep -q "# <<< env_setup foo <<<" "${BASH_PLUGIN}"; then
    echo "FAIL: end marker not found" >&2
    exit 1
fi

echo "Running test: idempotency and replacement without duplication..."
update_bash_plugin_block "foo" <<'EOF'
export FOO=2
EOF

COUNT_BEGIN=$(grep -c "# >>> env_setup foo >>>" "${BASH_PLUGIN}")
if [ "${COUNT_BEGIN}" -ne 1 ]; then
    echo "FAIL: expected exactly 1 begin marker, got ${COUNT_BEGIN}" >&2
    exit 1
fi
if grep -q "export FOO=1" "${BASH_PLUGIN}"; then
    echo "FAIL: old content FOO=1 should have been replaced" >&2
    exit 1
fi
if ! grep -q "export FOO=2" "${BASH_PLUGIN}"; then
    echo "FAIL: new content FOO=2 not found" >&2
    exit 1
fi

echo "Running test: multiple independent components..."
update_bash_plugin_block "bar" <<'EOF'
export BAR=hello
EOF

if ! grep -q "export FOO=2" "${BASH_PLUGIN}"; then
    echo "FAIL: foo block lost after adding bar" >&2
    exit 1
fi
if ! grep -q "export BAR=hello" "${BASH_PLUGIN}"; then
    echo "FAIL: bar block not found" >&2
    exit 1
fi

echo "Running test: legacy line cleanup..."
# Append legacy un-marked lines
cat <<'EOF' >> "${BASH_PLUGIN}"
# [legacy-item]
export LEGACY_VAR=stale
EOF

update_bash_plugin_block "legacy-item" \
    '/^# \[legacy-item\]$/d' \
    '/^export LEGACY_VAR=/d' <<'EOF'
export LEGACY_VAR=fresh
EOF

if grep -q "export LEGACY_VAR=stale" "${BASH_PLUGIN}"; then
    echo "FAIL: stale legacy line still exists" >&2
    exit 1
fi
if ! grep -q "export LEGACY_VAR=fresh" "${BASH_PLUGIN}"; then
    echo "FAIL: fresh replacement not found" >&2
    exit 1
fi

echo "Running test: empty block deletion..."
update_bash_plugin_block "to_delete" <<'EOF'
export TEMP=123
EOF
if ! grep -q "export TEMP=123" "${BASH_PLUGIN}"; then
    echo "FAIL: block to delete was not created" >&2
    exit 1
fi

update_bash_plugin_block "to_delete" <<'EOF'
EOF

if grep -q "env_setup to_delete" "${BASH_PLUGIN}"; then
    echo "FAIL: empty update should remove marker block" >&2
    exit 1
fi
if grep -q "export TEMP=123" "${BASH_PLUGIN}"; then
    echo "FAIL: content should be removed" >&2
    exit 1
fi

echo "ALL TESTS PASSED ✔"
