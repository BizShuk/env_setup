#!/bin/bash

source settings.sh

openssl_ver="1.0.2f"
openssl_name="openssl-$openssl_ver"
opensll_path="$idir/lib/openssl"

cd $idir/lib
curl --remote-name http://www.openssl.org/source/$openssl_name.tar.gz
tar -xzvf openssl-1.0.2f.tar.gz
cd openssl-1.0.2f

./configure darwin64-x86_64-cc --prefix=$idir/lib/openssl
make
make install

echo "# openssl" >> $idir/.bash_plugin
echo "export PATH=$openssl_path/bin:\$PATH" >> $idir/.bash_plugin
echo "export MANPATH=$openssl_path/ssl/man:\$MANPATH" >> $idir/.bash_plugin
