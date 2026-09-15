#!/bin/bash
set -euo pipefail

# ============================================================================
# test_docker_install.sh — Docker container test runner for env_setup
# ============================================================================
# Launches an isolated Ubuntu container, executes core development toolchain
# bootstrap scripts (Go, Node.js, Git, Vim), builds the env_setup CLI, asserts
# installed command functionality, and ensures container destruction on exit.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Step 1: Preflight check for Docker daemon accessibility
if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker daemon is not accessible or not running." >&2
    echo "Please ensure Docker Desktop, Colima (e.g. 'colima start'), or dockerd is running." >&2
    exit 1
fi

# Step 2: Set unique container name and image
CONTAINER_NAME="env_setup_test_$(date +%s)_$$"
IMAGE_NAME="${DOCKER_TEST_IMAGE:-ubuntu:26.04}"

# Step 3: Register trap for automatic cleanup on exit or termination
cleanup() {
    local exit_code=$?
    echo "Cleaning up container: ${CONTAINER_NAME}..."
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    exit "${exit_code}"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Step 4: Start isolated container mounting repo read-only to /repo
echo "Starting test container: ${CONTAINER_NAME} (${IMAGE_NAME})..."
docker run -d \
    --name "${CONTAINER_NAME}" \
    -v "${REPO_DIR}:/repo:ro" \
    -w /workspace \
    -e DEBIAN_FRONTEND=noninteractive \
    "${IMAGE_NAME}" \
    sleep infinity

# Step 5: Execute toolchain installations and assertions inside container
echo "Running installation and verification in container..."
docker exec -i "${CONTAINER_NAME}" bash <<'EOF'
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Copy repository from read-only mount to internal container workspace
mkdir -p /workspace && cp -a /repo/. /workspace/ && cd /workspace

echo "=== Phase 1: Installing base prerequisites ==="
apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    sudo \
    tar \
    build-essential \
    git \
    python3 \
    python3-dev

# Install universal-ctags or fallback for ctags requirement in vim.sh
apt-get install -y --no-install-recommends universal-ctags || apt-get install -y --no-install-recommends ctags || true

# Git safe directory configuration for mounted workspace
git config --global --add safe.directory /workspace
git config --global --add safe.directory '*'

# Ensure ~/projects/env_setup symlink exists for settings.sh convention
mkdir -p "${HOME}/projects"
ln -sf /workspace "${HOME}/projects/env_setup"

# Ensure PATH includes user binary paths
export PATH="${HOME}/bin:${HOME}/.local/bin:${PATH}"

echo "=== Phase 2: Running toolchain installation scripts ==="
echo "--> Installing Go..."
./scripts/go.sh

if [ -f "${HOME}/.bash_plugin" ]; then
    # shellcheck disable=SC1090
    source "${HOME}/.bash_plugin"
fi
export PATH="${HOME}/bin:${HOME}/.local/bin:${PATH}"

echo "--> Installing Node.js & pnpm..."
./scripts/nodejs.sh

if [ -f "${HOME}/.bash_plugin" ]; then
    # shellcheck disable=SC1090
    source "${HOME}/.bash_plugin"
fi

echo "--> Installing Git..."
./scripts/git.sh

echo "--> Installing Vim..."
./scripts/vim.sh

if [ -f "${HOME}/.bash_plugin" ]; then
    # shellcheck disable=SC1090
    source "${HOME}/.bash_plugin"
fi
export PATH="${HOME}/bin:${HOME}/.local/bin:${PATH}"

echo "=== Phase 3: Validating pure shell scripts and test suite ==="
pnpm run lint
pnpm test

echo "=== Phase 4: Asserting installed commands ==="
echo -n "Checking go: " && go version
echo -n "Checking node: " && node -v
echo -n "Checking pnpm: " && pnpm -v
echo -n "Checking npm is absent: " && { command -v npm >/dev/null 2>&1 && { echo "FAIL (npm found at $(command -v npm))"; exit 1; } || echo "OK"; }
echo -n "Checking git: " && git --version
echo -n "Checking vim: " && vim --version | head -n 1
echo "Checking scripts/system/os.sh:"
./scripts/system/os.sh
echo "Checking scripts/system/cpu.sh:"
./scripts/system/cpu.sh

echo "=== Phase 5: Asserting macOS tasks exit 0 on Linux ==="
./bin/mac/launch_audit-mac.sh
./bin/mac/login_audit-mac.sh
./bin/mac/network_security_audit-mac.sh
./scripts/backup/list.sh
./scripts/backup/backup.sh
./scripts/backup/init.sh
./scripts/backup/import.sh
./scripts/dump/mac.sh
./scripts/uninstall/codex.sh
./scripts/mac.sh
./scripts/mac_basic.sh
./scripts/openssl_mac_setup.sh
echo "All macOS tasks exited 0 successfully on Linux container!"

echo "=== Verification completed successfully! ==="
EOF

echo "All tests passed successfully in container: ${CONTAINER_NAME}"
