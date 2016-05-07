#!/bin/bash

. ./settings.sh

ln -sf $pkg_sdir/ubuntu_desktop/xdg/user-dirs.dirs $idir/.config/user-dirs.dirs
ln -sf $pkg_sdir/ubuntu_desktop/xdg/user-dirs.locale $idir/.config/user-dirs.locale
sudo ln -sf $pkg_sdir/ubuntu_desktop/xdg/user-dirs.defaults /etc/xdg/user-dirs.defaults
sudo ln -sf $pkg_sdir/ubuntu_desktop/xdg/user-dirs.conf /etc/xdg/user-dirs.conf

