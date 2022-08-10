#!/bin/bash

### show device uuid
lsblk -f
sudo blkid

### proejct folder
mount /dev/sda1 /home/shuk/project

### Config folder
mount /dev/sda5 /home/shuk/project_config

