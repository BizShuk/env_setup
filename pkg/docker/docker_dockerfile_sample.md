```
# base image
FROM ubuntu:14.04
MAINTAINER bizshuk <biz.shuk@gmail.com>


# basic setup ( must install )
RUN     apt-get update && apt-get upgrade -y
RUN     apt-get install -y build-essential
RUN     apt-get install -y git curl vim

# env setup
RUN     apt-get install -y libssl-dev  libpq-dev automake


# add user first , new user dont has passwd and sudo auth
#RUN     useradd -m -s /bin/bash git
USER git
WORKDIR /home/git


# openresty setting
RUN     git clone http://192.168.2.52:3000/shuk/openresty_setting.git
RUN     cd openresty_setting; /bin/bash -c ./server_install.sh; /bin/bash -c ./lua_conf_setup.sh;
RUN     chmod +x /root:



EXPOSE 8000 8888
CMD ["/root/openresty/nginx/sbin/nginx","-g","daemon off;"]



# note and undoc

#ONBUILD [ADD/RUN]


#ENV ubuntu_version=14.04
#ENV abc=hello def=$ubuntu_version
#ADD <src> <dest> ,  <src> 可以是 Dockerfile 所在目錄的相對路徑
#ENV
#VOLUME


#ADD
#COPY
#For the ADD and COPY instructions, the contents of the file(s) in the image are examined and a checksum is calculated for each file. The last-modified and last-accessed times of the file(s) are not considered in these checksums. During the cache lookup, the checksum is compared against the checksum in the existing images. If anything has changed in the file(s), such as the contents and metadata, then the cache is invalidated.
#In the case where <src> is a remote file URL, the destination will have permissions of 600. If the remote file being retrieved has an HTTP Last-Modified header, the timestamp from that header will be used to set the mtime on the destination file. However, like any other file processed during an ADD, mtime will not be included in the determination of whether or not the file has changed and the cache should be updated.

```
