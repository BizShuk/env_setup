#!/bin/bash

source settings.sh

pcre_ver="8.38"
pcre_name="pcre-${pcre_ver}"
nginx_ver="1.9.14"
nginx_name="nginx-${nginx_ver}"
nginx_path="$INSTALL_DIR/nginx"
nginx_conf_path="$REPO_DIR/pkg/nginx/nginx.conf"

mkdir $INSTALL_DIR/lib/$pcre_name


pushd ~/lib
    wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/${pcre_name}.tar.gz
    tar zxvf $pcre_name.tar.gz && rm $pcre_name.tar.gz
popd


sudo apt-get install -y libssl-dev


tmpdir=`mktemp -d`

pushd "$tmpdir"
    wget http://hg.nginx.org/nginx/archive/release-${nginx_ver}.tar.gz
    tar zxvf release-${nginx_ver}.tar.gz && rm release-${nginx_ver}.tar.gz

    pushd nginx-release-${nginx_ver}
        ./auto/configure --prefix=$nginx_path \
                        --with-pcre-jit \
                        --with-pcre=$USER_LIB/pcre-8.38 \
                        --with-http_ssl_module \
                        --with-poll_module \
                        --with-ipv6

# --with-ipv6 --with-http_ssl_module --with-http_realip_module --with-http_addition_module --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_stub_status_module --with-mail --with-mail_ssl_module --with-file-aio --with-cc-opt='-O2 -g -pipe -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic'

        make
        make install
    popd
popd
rm -rf $tmpdir

echo "# NGINX" >> $INSTALL_DIR/.bash_plugin
echo "export PATH=$nginx_path/sbin:\$PATH" >> $INSTALL_DIR/.bash_plugin
ln -sf $nginx_conf_path $nginx_path/conf/nginx.conf
ln -sf $nginx_path/logs $USER_LOG/nginx
