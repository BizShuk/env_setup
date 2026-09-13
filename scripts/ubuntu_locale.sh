#!/bin/bash
set -euo pipefail

# ============================================================================
# ubuntu_locale.sh — Generate and configure locales on Ubuntu
# ============================================================================

source "$(dirname "$0")/settings.sh"

sudo locale-gen zh_TW.UTF-8 en_US.UTF-8

sudo update-locale LANG="en_US.UTF-8"
sudo update-locale LANGUAGE="en_US.UTF-8"
sudo update-locale LC_CTYPE="zh_TW.UTF-8"
sudo update-locale LC_NUMERIC="en_US.UTF-8"
sudo update-locale LC_TIME="en_US.UTF-8"
sudo update-locale LC_COLLATE="en_US.UTF-8"
sudo update-locale LC_MONETARY="en_US.UTF-8"
sudo update-locale LC_MESSAGES="en_US.UTF-8"
sudo update-locale LC_PAPER="en_US.UTF-8"
sudo update-locale LC_NAME="en_US.UTF-8"
sudo update-locale LC_ADDRESS="en_US.UTF-8"
sudo update-locale LC_TELEPHONE="en_US.UTF-8"
sudo update-locale LC_MEASUREMENT="en_US.UTF-8"
sudo update-locale LC_IDENTIFICATION="en_US.UTF-8"
sudo update-locale LC_ALL=""
