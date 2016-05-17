
[Scratch](http://kubernetes.io/v1.0/docs/getting-started-guides/scratch.html)
[network model](http://kubernetes.io/v1.0/docs/admin/networking.html)




export KUBE_VERSION=1.0.5
export FLANNEL_VERSION=0.5.0
export ETCD_VERSION=2.2.0



export nodes="shuk@10.10.80.80" # vcap@10.10.103.162 vcap@10.10.103.223"
export role="ai i i"
export NUM_MINIONS=${NUM_MINIONS:-3}
export SERVICE_CLUSTER_IP_RANGE=192.168.3.0/24
export FLANNEL_NET=172.16.0.0/16


?????? proxy


KUBERNETES_PROVIDER=ubuntu ./kube-up.sh
