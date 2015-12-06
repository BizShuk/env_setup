## enviroment setup

This repo is for bash of ubuntu and Mac.

## TODO
- setup nodejs
- setup docker
- setup kubernetes
- bash/README.md

sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
It updates /etc/default/locale with provided values.


LANG=en_US.UTF-8
LC_CTYPE=en_US.UTF-8
LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8


sudo locale-gen en_US en_US.UTF-8
sudo dpkg-reconfigure locales 


## What is including?
- Sublime settings ( markdown syntax ) replace manually
- Git short command
- Docker useful command ( denv )


## How to use?
- **[Ubuntu]** exec `cd setup; ./install_ubuntu.sh`
- **[Mac]** exec `cd setup; ./install_mac.sh`



## cmd usage
- `git_projects` , this is showing whether git repos need to update or push in $project_dir or not.  
- `denv` , inherite from docker and add some easy use option  





