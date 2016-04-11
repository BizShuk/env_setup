#!/bin/bash
source settings.sh

# ref link http://www.working-software.com/node/30

psql_ver="9.5.2"

psql_path="$idir/lib/postgres-${psql_ver}"
psql_data="$idir/data/postgres"

# create user and group
sudo dscl . -create /Users/postgres UniqueID 174
sudo dscl . -create /Users/postgres PrimaryGroupID 174
sudo dscl . -create /Users/postgres HomeDirectory /usr/local/pgsql
sudo dscl . -create /Users/postgres UserShell /usr/bin/false
sudo dscl . -create /Users/postgres RealName "PostgreSQL Administrator"
sudo dscl . -create /Users/postgres Password \*
dscl . -read /Users/postgres
sudo dscl . -create /Groups/postgres PrimaryGroupID 174
sudo dscl . -create /Groups/postgres Password \*
dscl . -read /Groups/postgres


wget https://ftp.postgresql.org/pub/source/v${psql_ver}/postgresql-${psql_ver}.tar.gz
tar zxvf postgressql-${psql_ver}.tar.gz

pushd postgresql-${psql_ver}
    ./configure --prefix=${psql_path} -j8
    make -j8
    make install
popd

echo "PATH=${psql_path}/bin:\$PATH" > .bash_plugin

mkdir -P $psql_data && sudo chown postgres:postgres $psql_data
# init db
sudo -u postgres $psql_path/bin/initdb -D $psql_data
# start service
sudo -u postgres $psql_path/bin/pg_ctl -D $psql_data start  



echo "connect with psql -U <username> -W [-W for passwd prompt]" 
echo "psql list commands: http://alvinalexander.com/blog/post/postgresql/what-are-available-listing-commands-in-postgresql"



