#!/bin/bash

source settings.sh

pcre_ver="8.38"
pcre_name="pcre-${pcre_ver}"
nginx_ver="1.9.14"
nginx_name="nginx-${nginx_ver}"
nginx_path="$idir/nginx"
nginx_conf_path="$sdir/pkg/nginx/nginx.conf"

mkdir $idir/lib/$pcre_name


pushd ~/lib
    wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/${pcre_name}.tar.gz
    tar zxvf $pcre_name.tar.gz && rm $pcre_name.tar.gz
popd


sudo apt-get install -y libssl-dev

wget http://hg.nginx.org/nginx/archive/release-${nginx_ver}.tar.gz
tar zxvf release-${nginx_ver}.tar.gz && rm release-${nginx_ver}.tar.gz

pushd nginx-release-${nginx_ver}
    ./auto/configure --prefix=$nginx_path \
                    --with-pcre-jit \
                    --with-pcre=$idir/lib/pcre-8.38 \
                    --with-http_ssl_module
    make
    make install
popd

rm -r nginx-release-${nginx_ver}

echo "# NGINX" >> $idir/.bash_plugin
echo "export PATH=$nginx_path/sbin:\$PATH" >> $idir/.bash_plugin
ln -sf $nginx_conf_path $nginx_path/conf/nginx.conf
