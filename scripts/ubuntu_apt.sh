#!/bin/bash
set -euo pipefail

# ============================================================================
# ubuntu_apt.sh — Update package cache and install core Ubuntu packages
# ============================================================================

source "$(dirname "$0")/settings.sh"

# Update and Upgrade
sudo apt-get update && sudo apt-get upgrade -y

# Dev packages
sudo apt-get install -y build-essential update-locale locales
sudo apt-get install -y autoconf make cmake
sudo apt-get install -y python3-dev
sudo apt-get install -y openssh-server libssl-dev
sudo apt-get install -y whois

# User utilities
sudo apt-get install -y jq screen colordiff wget curl dnsutils ibus-chewing

# Input method (fcitx)
sudo apt-get install -y fcitx-mozc fcitx-googlepinyin --install-suggests
