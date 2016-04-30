#!/bin/bash

. settings.sh

sudo mv $sdir/pkg/postgresql/postgres.list /etc/apt/sources.list.d/
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get install -y postgresql-9.4
