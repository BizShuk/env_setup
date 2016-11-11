#!/bin/bash

source settings.sh


sublime_ver="3"

echo $pkg_sdir
config_path="$idir/.config/sublime-text-$sublime_ver"

mkdir -p $config_path


install_pkg_path="$config_path/Installed Packages"
pkg_path="$config_path/Packages"




cp -r $pkg_sdir/sublime/MarkdownEditing  "$install_pkg_path/"
cp -r $pkg_sdir/sublime/User  "$pkg_path/"


