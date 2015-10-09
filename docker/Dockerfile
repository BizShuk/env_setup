#!/bin/bash
From ubuntu:14.04
MAINTAINER bizshuk <biz.shuk@gmail.com>

ENV username shuk
ENV password zxcvasdf

# copy from https://github.com/BizShuk/env_setup.git/ubuntu_update_install.sh
RUN     apt-get update && apt-get upgrade -y
RUN     apt-get install git vim curl wget build-essential screen openssh-server automake -y

# install lib
RUN     apt-get install libssl-dev -y

# change timezone to Asia/Taipei
RUN     cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime


### [root]
#add default user
RUN     useradd -m -s /bin/bash -G sudo $username
RUN     echo "$password\n$password\n" | passwd $username

# basic env setup
ADD     https://github.com/BizShuk/env_setup/archive/master.tar.gz /tmp/master.tar.gz
RUN     tar -zvxf /tmp/master.tar.gz -C /tmp && mv /tmp/env_setup-master /home/$username/env_setup && chown -R $username /home/$username/env_setup


### [user]
USER $username
WORKDIR /home/$username

RUN     cd ~/env_setup; /bin/bash -c ./bash_env_setup.sh;


USER root
WORKDIR /root

RUN mkdir /var/run/sshd

#RUN echo 'root:root' |chpasswd
#RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
#RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config

CMD ["/usr/sbin/sshd","-D"]


