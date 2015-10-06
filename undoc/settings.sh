#!/usr/bin/env bash

# base path
install_dir=$HOME
setting_dir=$PWD


# reposory
repository_location="http://192.168.2.52:3000"

lua_repo=$repository_location/shuk/lua.git
lua_testing_repo=$repository_location/shuk/lua_test.git


# openresty install related
openresty_dir=$install_dir/openresty
setting_openresty_dir=$setting_dir/ngx_openresty-1.7.10.2
nginx_path=$openresty_dir/nginx
nginx_conf_path=$nginx_path/conf/nginx.conf

nginx_default_file="nginx.conf.default"

# libraries
lib_dir=$install_dir/lib
setting_lib_dir=$setting_dir/external_lib

pcre_jit_version=pcre-8.36
pcre_jit_dir=$lib_dir/$pcre_jit_version



# lua path
lua_dir=$install_dir/lua


# 正式機
lua_server_port="8000"
lua_server_root="$install_dir/lua"    # root dir
lua_server_log="logs"
lua_server_log_access="$lua_server_log/ngx.access.log main"
lua_server_log_error="$lua_server_log/ngx.error.log"


# 測試機
lua_server_testing_port="8888"
lua_server_testing_root="$install_dir/lua_test"    # root dir
lua_server_testing_log="logs"
lua_server_testing_log_access="$lua_server_testing_log/ngx.testing.access.log main"
lua_server_testing_log_error="$lua_server_testing_log/ngx.testing.error.log"


