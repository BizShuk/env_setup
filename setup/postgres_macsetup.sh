#!/bin/bash
source settings.sh

# ref link http://www.working-software.com/node/30

psql_ver="9.5.2"
psql_name="postgresql-${psql_ver}"
psql_path="$idir/lib/${psql_name}"

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

tmp_dir=`mktemp -d`

wget https://ftp.postgresql.org/pub/source/v${psql_ver}/${psql_name}.tar.gz -O
tar zxvf ${psql_name}.tar.gz && rm ${psql_name}.tar.gz

psql_name=${psql_name:0:${#psql_name}-2}        # remove 9.5.2 to 9.5

pushd ${psql_name}
    ./configure --prefix=${psql_path} 
    make 
    make install
popd
rm -rf - ${psql_name}

echo "export PATH=${psql_path}/bin:\$PATH" >> .bash_plugin

mkdir -P $psql_data && sudo chown postgres:postgres $psql_data
# init db
sudo -u postgres $psql_path/bin/initdb -D $psql_data
# start service
sudo -u postgres $psql_path/bin/pg_ctl -D $psql_data start  
# stop service
sudo -u postgres $psql_path/bin/pg_ctl -D $psql_data stop


echo "connect with psql -U <username> -W [-W for passwd prompt]" 
echo "psql list commands: http://alvinalexander.com/blog/post/postgresql/what-are-available-listing-commands-in-postgresql"



