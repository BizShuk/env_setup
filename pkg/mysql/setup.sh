#!/bin/bash


. ~/settings.sh

# Config List:
# /etc/mysql/my.cnf
# /etc/mysql/conf.d/
# /etc/mysql/mysql.conf.d/


sudo apt-get install mysql

MYSQL_PKG_DIR="${REPO_PKG}/mysql"

sudo cp ${MYSQL_PKG_DIR}/conf.d/* /etc/mysql/conf.d/
