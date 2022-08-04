#!/bin/bash

source settings.sh



psql_ver="9.5.2"
psql_name="postgresql-${psql_ver}"
psql_path="$INSTALL_DIR/lib/${psql_name}"
psql_log="$INSTALL_DIR/log/postgre.log"
psql_data="$INSTALL_DIR/data/postgres"


user="$(whoami)"
tmp_dir=`mktemp -d`


sudo apt-get install libreadline-dev # libreadline6-dev

pushd $tmp_dir
    wget https://ftp.postgresql.org/pub/source/v${psql_ver}/${psql_name}.tar.gz
    tar zxvf ${psql_name}.tar.gz && rm ${psql_name}.tar.gz

    pushd ${psql_name}
        ./configure --prefix=${psql_path}
        make
        make install
    popd
popd

rm -rf ${tmp_dir}


echo "# Postgres" >> ~/.bash_plugin
echo "export PATH=${psql_path}/bin:\$PATH" >> ~/.bash_plugin
echo "export PGDATA=${psql_data}" >> ~/.bash_plugin
source ~/.bash_plugin

mkdir -p $psql_data

# init db
$psql_path/bin/initdb -U $user
ln -sf $REPO_PKG/postgresql/postgresql.conf ${psql_data}/postgresql.conf
# start service
$psql_path/bin/pg_ctl start
$psql_path/bin/psql -c "create database $user" postgres                         # init user database
$psql_path/bin/psql -c "create database gogs"                                           # for gogs database
$psql_path/bin/psql -c "alter user ${user} with PASSWORD '${passwd}'"   # change default user passwd


echo "If data directory is not specific , env PGDATA will be used."
echo "connect with psql -U <username> -W [-W for passwd prompt]"
echo "psql list commands: http://alvinalexander.com/blog/post/postgresql/what-are-available-listing-commands-in-postgresql"



# Apt-get way

#sudo mv $REPO_DIR/pkg/postgresql/postgres.list /etc/apt/sources.list.d/
#wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
#sudo apt-get update
#sudo apt-get install -y postgresql-9.5
# ref link http://www.working-software.com/node/30
