#!/bin/bash
# docker.sh: 清理未使用的 Docker containers, images 與 build cache
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/_lib_cleanup.sh"

print_help() {
    echo "Usage: $(basename "$0") [--apply] [--yes|-y] [--dry-run|-n] [--help|-h]"
    echo "清理未使用的 Docker 容器、映像檔與建置快取。"
    echo ""
    echo "Options:"
    echo "  --apply        執行實際清理 (預設為預覽模式 Preview Mode)"
    echo "  --yes, -y      自動確認，跳過個別確認提示"
    echo "  --dry-run, -n  預覽待清理目標與預估大小 (預設行為)"
    echo "  --help, -h     顯示此說明訊息"
}

parse_cleanup_args "$@"

if ! command -v docker >/dev/null 2>&1; then
    echo "提示: 系統未安裝 docker，略過 Docker 清理。"
    exit 0
fi

if ! docker info >/dev/null 2>&1; then
    echo "提示: Docker daemon 未啟動或無法連線，略過 Docker 清理。"
    exit 0
fi

if [ "${APPLY}" != true ]; then
    echo "=================================================================="
    echo " [Preview Mode] Docker 空間使用與可回收空間預覽 (Dry-run)"
    echo "=================================================================="
    docker system df
    echo ""
    print_preview_footer
    exit 0
fi

print_apply_header "Docker"

if confirm_action "未使用的 Docker containers (docker container prune -f)"; then
    docker container prune -f
    echo "  ✓ 已清理 unused containers"
fi

if confirm_action "未使用的 Docker images (docker image prune -a -f)"; then
    docker image prune -a -f
    echo "  ✓ 已清理 unused images"
fi

if confirm_action "Docker build cache (docker builder prune -f)"; then
    docker builder prune -f
    echo "  ✓ 已清理 build cache"
fi

echo ""
echo "完成: Docker 清理完畢。"
