#!/bin/bash

. ./settings.sh

ln -sf $REPO_PKG/ubuntu_desktop/xdg/user-dirs.dirs $INSTALL_DIR/.config/user-dirs.dirs
ln -sf $REPO_PKG/ubuntu_desktop/xdg/user-dirs.locale $INSTALL_DIR/.config/user-dirs.locale
cat $REPO_PKG/ubuntu_desktop/xdg/user-dirs.defaults | sudo tee -a /etc/xdg/user-dirs.defaults
cat $REPO_PKG/ubuntu_desktop/xdg/user-dirs.conf | sudo tee -a /etc/xdg/user-dirs.conf

