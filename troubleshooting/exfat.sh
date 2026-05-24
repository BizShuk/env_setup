#!/bin/bash

sudo dmesg | grep -i mount
# => exFAT-fs (sdc1): Volume was not properly unmounted. Some data may be corrupt. Please run fsck

# This is check whether exFAT is supported in filesystem
sudo apt install exfatprogs # install modprobe for exfat
sudo modprobe -v exfat
cat /proc/filesystems | grep fat
# => Should show exfat

# If
git clone https://github.com/arter97/exfat-linux
make
sudo make install
sudo modprobe exfat

# mod disk
sudo mount -t exfat /etc/sdc1 /home/shuk/transcend -o uid=shuk,gid=shuk

sudo apt-get install smartmontools
sudo smartctl -a /dev/sdc
# shuk@shuk-LIVA-Z:~/projects/env_setup/setup$ sudo smartctl -a /dev/sdc1
# smartctl 7.4 2023-08-01 r5530 [x86_64-linux-6.8.0-52-generic] (local build)
# Copyright (C) 2002-23, Bruce Allen, Christian Franke, www.smartmontools.org

# === START OF INFORMATION SECTION ===
# Vendor:               StoreJet
# Product:              Transcend
# Revision:             0
# Compliance:           SPC-4
# User Capacity:        960,197,124,096 bytes [960 GB]
# Logical block size:   512 bytes
# LU is fully provisioned
# Rotation Rate:        Solid State Device
# Form Factor:          2.5 inches
# Logical Unit id:      0x5000000000000001
# Serial number:        10008405241G942972C2
# Device type:          disk
# Local Time is:        Wed Jan 29 00:23:35 2025 CST
# SMART support is:     Available - device has SMART capability.
# SMART support is:     Enabled
# Temperature Warning:  Disabled or Not Supported

# === START OF READ SMART DATA SECTION ===
# SMART Health Status: OK
# Current Drive Temperature:     0 C
# Drive Trip Temperature:        0 C

# Error Counter logging not supported

# Device does not support Self Test logging

# Show the block device id
blkid /dev/sdc1

# ubuntu drive spindown time
sudo apt install hd-idle

sudo apt install hd-idle
sudo hd-idle -i 0 -a /dev/sdc  # No spin down time
sudo hd-idle -i 0 -a /dev/sdc1 # No spin down time

sudo smartctl -a /dev/sdc

# 非破壞性檢查:  (將 /dev/sdb 替換為您的 USB 裝置)
sudo badblocks -v /dev/sdc

# 檢查檔案系統是否有錯誤： (將 /dev/sdb1 替換為您的 USB 裝置)
sudo fsck /dev/sdc1
