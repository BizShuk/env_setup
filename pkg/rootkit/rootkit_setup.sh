#!/bin/bash

sudo apt-get install chkrootkit
sudo chkrootkit


sudo apt-get install rkhunter
sudo rkhunter --check
sudo rkhunter --update
