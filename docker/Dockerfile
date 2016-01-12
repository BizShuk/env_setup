#!/bin/bash
FROM ubuntu:14.04
MAINTAINER bizshuk <biz.shuk@gmail.com>

ENV username shuk
ENV password zxcvasdf

# copy from https://github.com/BizShuk/env_setup.git/setup_ubuntu_update.sh
RUN     apt-get update && apt-get upgrade -y
RUN     apt-get install git vim curl wget build-essential screen openssh-server automake -y

# install lib
RUN     apt-get install libssl-dev -y

# change timezone to Asia/Taipei
RUN     cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime

# DHCP
# use bridge and docker run with privileged mode
# if you want to get right ip by mac and hostname , you need to put dns(dhcp) server domain in /etc/resolv.conf first line
# and "/usr/bin/dhclient -r && /usr/bin/dhclient" twice
RUN     cp /sbin/dhclient /usr/bin/dhclient





#add default user
RUN     useradd -m -s /bin/bash -G sudo $username
RUN     echo "$password\n$password\n" | passwd $username

# download env_stup , because file by ADD will be owner root
ADD     https://github.com/BizShuk/env_setup/archive/master.tar.gz /tmp/master.tar.gz
RUN     tar -zvxf /tmp/master.tar.gz -C /tmp && mv /tmp/env_setup-master /home/$username/env_setup && chown -R $username /home/$username/env_setup


### [user]
USER $username
WORKDIR /home/$username

# setup bash env
RUN     cd ~/env_setup/setup; /bin/bash -c ./setup_bash_env.sh;


USER root
WORKDIR /root


# solution of  sshd problem in docker container
RUN mkdir /var/run/sshd
#RUN echo 'root:root' |chpasswd
#RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
#RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

CMD ["/usr/sbin/sshd","-D"]


