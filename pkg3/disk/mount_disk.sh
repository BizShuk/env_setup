#!/bin/bash

### show device uuid
lsblk -f
sudo blkid

PROJECT_PATH="/home/shuk/projects"
PROJECT_CONFIG_PATH="/home/shuk/project_config"

### proejct folder
mount /dev/sda1 ${PROJECT_PATH}

### Config folder
mount /dev/sda5  ${PROJECT_CONFIG_PATH}

### eject device

eject <device>


