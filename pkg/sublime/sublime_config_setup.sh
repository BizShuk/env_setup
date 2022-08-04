#!/bin/bash

source settings.sh


sublime_ver="3"

echo $REPO_PKG
config_path="$INSTALL_DIR/.config/sublime-text-$sublime_ver"

mkdir -p $config_path


install_pkg_path="$config_path/Installed Packages"
pkg_path="$config_path/Packages"




cp -r $REPO_PKG/sublime/MarkdownEditing  "$install_pkg_path/"
cp -r $REPO_PKG/sublime/User  "$pkg_path/"


