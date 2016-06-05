## reference
ref. [docker gitbook](http://philipzheng.gitbooks.io/docker_practice/content/)
ref. [docker ](http://zx-1986.blogspot.tw/2014/10/docker.html)
ref. [docker concept](http://lab.howie.tw/2014/08/docker-docker-lxc-hypervisor.html)
ref. [understand docker architecture](https://docs.docker.com/introduction/understanding-docker/)




### requirement
if **kernel version is older than 3.13** , you must upgrade it with below:
`sudo apt-get install linux-image-generic-lts-trusty`

    linux-image-generic-lts-trusty  Generic Linux kernel image. This kernel has AUFS built in. This is required to run Docker.
    linux-headers-generic-lts-trusty    Allows packages such as ZFS and VirtualBox guest additions which depend on them. If you didn’t install the headers for your existing kernel, then you can skip these headers for the”trusty” kernel. If you’re unsure, you should include this package for safety.
    xserver-xorg-lts-trusty        as below
    libgl1-mesa-glx-lts-trusty





## intallation

    sudo apt-get update
    sudo apt-get install curl
    curl -sSL https://get.docker.com/ | sh

    # for test installation
    sudo docker run hello-world





## basic note

1. without sudo : add user to group "docker"
2. DHCP
    1. docker run with `--privileged` and hostname
    2. resave `/etc/resolv.conf`
    3. mv `/sbin/dhclient` to `/usr/sbin/dhclient`
    4. `dhclient -r;dhclient` twice
3. container watch pid=0 process . If that is down , container will stop.



-H for daemon host

## basic cmd

##### show system info of daemon
`docker info`


### about image

##### show local image list
`docker images`

##### remove local image
`docker rmi $image_id`

##### build image from dockerfile
`docker build -t="[username/]image_name"  Dockerfile_path`
- username  , ex : bizshuk or docker hubs account
- image_name , ex : gogs

##### tag image
`docker tag image_id[:tag]  [repo_name/][username/]name[:tag]`
ex: `sudo docker tag  3075c8 lua_server:1.1`



### about container

##### show live container
`docker ps`
- -a , show all container including stoped container
- -q , for show container id
- -l , for last created container

##### show container log
`docker log <container_id>`

##### run container 
`docker run -d -p 8000:8000 -p 8888:8888 -v /src/webapp:/opt/webapp:ro trois <image> [<cmd>]`
- -d , for daemon
- -p host_port:container_port ,  map host's port to container's port
- -i , for interactive mode
- -t , for tty
- -v , mount host's dir to container's dir with permission (default:read and write , ex:  read only `:ro`)
- --name , assign container name
ex: for bash in container `docker run -it -p 80:80 [$image_name] [$cmd , /bin/bash]`

##### start restart stop container
`docker start/restart/stop`

##### exec cmd in container
`docker exec -ti <cid or cname> <cmd>` 
ex: `docker exec -it <cname> /bin/bash`

##### attach pid=0 in container
`docker attach <cid or cname>`
當多個窗口同時 attach 到同一個容器的時候，所有窗口都會同步顯示。當某個窗口因命令阻塞時,其他窗口也無法執行操作了。

##### commit container to image
`docker commit -m "this is messgae" -a "author"  [container id] [image_name:tag_name]`



### undoc

##### get container ip
`docker images -a --no-trunc | head -n4 | grep -v "IMAGE ID" | awk '{ print $3 }' | xargs docker inspect | grep Comment`

##### show port of container binding or lookup 
`docker port <cid or cname> [<private_port>[/<protocol>]]`
