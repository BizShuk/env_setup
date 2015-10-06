# todo
#   1. in prefix = ../ ( $openresty_dir == ./ ) , then ln nginx.conf
#   2. check general installed dir , ex: pcre dir


source settings.sh

mkdir -p $lib_dir
cp -r $setting_lib_dir/$pcre_jit_version $lib_dir


cd $setting_openresty_dir
# need to remove test mode 
./configure --prefix=$openresty_dir \
            --with-luajit \
            --with-pcre=$pcre_jit_dir \
            --with-pcre-jit \
            -j8 \
            --with-http_stub_status_module \
            --with-debug \
&& make -j8 && make install 


