#!/bin/bash

# Clear system logs and temporary files:
sudo rm -rf /private/var/log/*
sudo rm -rf /private/var/tmp/*
sudo rm -rf /Library/Logs/*

# Clear user cache:
rm -rf ~/Library/Caches/*
# Clear system cache:
sudo rm -rf /Library/Caches/*

# Remove old Time Machine backups:
sudo tmutil deletelocalsnapshots /

# Remove unused Docker images and containers:
# check whether cmd docker exists if so run the command
command -v docker >/dev/null 2>&1 && docker system prune -a

# Empty the Trash:
rm -rf ~/.Trash/*
