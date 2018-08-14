# Kubernetes

### Issues

##### Kubernetes with IPVS
from [IPVS for Scaled Private Cloud Load Balancing [I] - Kimberly Messimer, Comcast VIPER](https://www.youtube.com/watch?v=KJ-A8LYriGI)
1. Address Resolution Protocol problem
2. Master/Backend colocation
3. iptable contention
4. Hariping mode problem








   livenessProbe:
      # an http probe
      httpGet:
        path: /_status/healthz
        port: 80
      # length of time to wait for a pod to initialize
      # after pod startup, before applying health checking
      initialDelaySeconds: 30
      timeoutSeconds: 1




      kind: pod

      command: ["/bin/echo","hello”,”world"]
command: ["/bin/echo"]
    args: ["hello","world"]


      restartPolicy: Never



By default, this will also cause the pods managed by the replication controller to be deleted. If there were a large number of pods, this may take a while to complete. If you want to leave the pods running, specify --cascade=false.

If you try to delete the pods before deleting the replication controller, it will just replace them, as it is supposed to do.



Display one or many resources.

Possible resources include pods (po), replication controllers (rc), services (svc), nodes, events (ev), component statuses (cs), limit ranges (limits), nodes (no), persistent volumes (pv), persistent volume claims (pvc) or resource quotas (quota).

kubectl get ep
NAME         ENDPOINTS


kubectl  api
http://kubernetes.io/v1.0/docs/user-guide/kubectl/kubectl.html



 kubectl run my-nginx --image=nginx --replicas=2 --port=80
$ kubectl expose rc my-nginx --port=80 --type=LoadBalancer


 kubectl stop replicationcontroller <pod_name> 
 = stop + delete

/kubectl scale --replicas=10 replicationcontrollers frontend



  kubectl get rc/web service/frontend pods/web-pod-13je7
  kubectl get -o template web-pod-13je7 --template={{.status.phase}} --api-version=v1
  // List a single replication controller with specified NAME in ps output format.
$ kubectl get replicationcontroller web

// List a single pod in JSON output format.
$ kubectl get -o json pod web-pod-13je7

$ kubectl get rc,services


kubectl describe se <name>


kubectl scale --replaca=5 ?????

-o json

stop
delete 

stop pod without shuting down rc , it'll growd back again
