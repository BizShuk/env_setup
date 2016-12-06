#!/usr/bin/env bash


dir=`mktemp -d`

pushd ${dir}
    # RootCA
    # [genrsa|gendsa] -aes[128|256] -des3 -des , length: 1024 , 2048 , 4096
    openssl genrsa -out RootCA.key 1024
    openssl req -new -key RootCA.key -out RootCA.req    # req signed with key = crt , and no more use
    openssl x509 -req -days 3650 -sha1 -extensions v3_ca -signkey RootCA.key -in RootCA.req -out RootCA.crt

    # ServerCA
    openssl genrsa -out ServerCA.key 1024
    openssl req -new -key ServerCA.key -out ServerCA.req
    openssl x509 -req -days 1000 -sha1 -extensions v3_req -CA RootCA.crt -CAkey RootCA.key -CAserial RootCA.srl -CAcreateserial -in ServerCA.req -out ServerCA.crt

    # ClientCA
    #openssl genrsa -des3 -out ClientCA.key 2048
    #openssl req -new -key ClientCA.key -out ClientCA.req
    #openssl x509 -req -days 730 -sha1 -extensions v3_req -CA RootCA.crt -CAkey RootCA.key  -CAserial RootCA.srl -CAcreateserial -in ClientCA.req -out ClientCA.crt
    #openssl pkcs12 -export -in ClientCA.crt -inkey ClientCA.key -out ClientCA.pfx
popd

ca_dir="CA_${dir#*.}"

mv ${dir} ./CA_${dir#*.}

echo "Result in ${ca_dir}"
