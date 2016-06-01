



### image 


multi image 疊合靠者`union mount` 將所有image的改變整合成一個file, 而不是取代之前的file [aufs or unionfs]

layer: 每一層的fs , top layer 可讀寫
parent image: ubuntu is mysql parent image
base image: ubuntu:14.04

每一層image 只能 read only ,只有top layer可以read and write (操作層)


基本上