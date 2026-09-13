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
IMAGE_NAME="${DOCKER_TEST_IMAGE:-ubuntu:24.04}"

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

echo "--> Installing Node.js & npm..."
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

echo "=== Phase 3: Building env_setup CLI ==="
mkdir -p tmp
go build -o tmp/env_setup .

echo "=== Phase 4: Asserting installed commands ==="
echo -n "Checking go: " && go version
echo -n "Checking node: " && node -v
echo -n "Checking npm: " && npm -v
command -v pnpm >/dev/null && echo -n "Checking pnpm: " && pnpm -v || true
echo -n "Checking git: " && git --version
echo -n "Checking vim: " && vim --version | head -n 1
echo "Checking env_setup system os show:"
./tmp/env_setup system os show
echo "Checking env_setup system cpu show:"
./tmp/env_setup system cpu show

echo "=== Verification completed successfully! ==="
EOF

echo "All tests passed successfully in container: ${CONTAINER_NAME}"
