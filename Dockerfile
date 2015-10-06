From ubuntu:14.04
MAINTAINER bizshuk <biz.shuk@gmail.com>

ENV username shuk
ENV password zxcvasdf

# copy from https://github.com/BizShuk/env_setup.git/ubuntu_update_install.sh
RUN     apt-get update && apt-get upgrade -y
RUN     apt-get install git vim curl wget build-essential screen openssh-server -y
RUN     service ssh start


### [root]

#add default user
RUN     useradd -m -s /bin/bash -G sudo $username
RUN     echo "$password\n$password\n" | passwd $username





### [user]
USER $username
WORKDIR /home/$username


# basic env setup
RUN     git clone https://github.com/BizShuk/env_setup.git;
RUN     cd ~/env_setup; /bin/bash -c ./bash_env_setup.sh;




CMD ["/bin/bash"]
