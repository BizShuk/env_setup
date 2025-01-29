#!/bin/bash

sudo fsck /dev/sda1
# fsck from util-linux 2.39.3
# exfatprogs version : 1.2.2
# ERROR: /project/default/personal/shuk/工作紀錄/htc interview/play-2.2.6/repository/local/org.scala-sbt/run/0.13.0: cluster 0x250ed2 is marked as free at 0x943c2c0000. Truncate (y/N)? n
# /dev/sda1: corrupted. directories 9925, files 97840
# /dev/sda1: files corrupted 1, files fixed 0

sudo smartctl -a /dev/sda1
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
# Local Time is:        Wed Jan 29 16:18:47 2025 CST
# SMART support is:     Available - device has SMART capability.
# SMART support is:     Enabled
# Temperature Warning:  Disabled or Not Supported

# === START OF READ SMART DATA SECTION ===
# SMART Health Status: OK
# Current Drive Temperature:     0 C
# Drive Trip Temperature:        0 C

# Error Counter logging not supported
