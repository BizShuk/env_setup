#!/bin/bash

. ./settings.sh

ln -sf $pkg_sdir/ubuntu_desktop/xdg/user-dirs.dirs $idir/.config/user-dirs.dirs
ln -sf $pkg_sdir/ubuntu_desktop/xdg/user-dirs.locale $idir/.config/user-dirs.locale
cat $pkg_sdir/ubuntu_desktop/xdg/user-dirs.defaults | sudo tee -a /etc/xdg/user-dirs.defaults
cat $pkg_sdir/ubuntu_desktop/xdg/user-dirs.conf | sudo tee -a /etc/xdg/user-dirs.conf

