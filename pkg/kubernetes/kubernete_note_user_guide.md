## kubectl remote api
[remote api](http://kubernetes.io/v1.0/docs/user-guide/kubectl/kubectl.html)








## basic note
resource type: 
- po(pods)
- rc(replication controllers) 
- se(services)
- no(nodes)
- ev(events)
- cs(component statuses)
- limits()
- pv(persistent volumes)
- pvc(persistent volume claims)
- quota(resource quotas)
- ep(end point)
- all

resource set:
=[<resource type>/<resource name>]+
=<resource type>[,<resource type>]* <resource name>[,<resource name>]*


## show service lits
`kubectl get <resource type>[,<resource type>]`
- -l , for labels condition , ex: -l app=lua
- -L , relabel
- -o template --template={{.status.phase}} ,
- -o json ,
- --api-version=v1 ,

other formate:
`kubectl get <resource set>`
`kubectl describe <resource set>`


##### create 
`kubectl run my-nginx --image=nginx --replicas=2 --port=80`
`kubectl create -f <yaml_file>`


##### delete se,rc,po
`kubectl delete <resource type> <resource name>`
 
`kubectl stop [<resource type> <resource name>]+`
 = stop + delete

    By default, this will also cause the pods managed by the replication controller to be deleted. If there were a large number of pods, this may take a while to complete. If you want to leave the pods running, specify --cascade=false.
    If you try to delete the pods before deleting the replication controller, it will just replace them, as it is supposed to do.



##### log
`kubectl logs hello-world` as docker log

##### scale app
`kubectl scale rc <resource_name> --replicas=<number>`



##### update , undoc yet


update partial data
$ kubectl patch rc my-nginx-v4 -p '{"metadata": {"annotations": {"description": "my frontend running nginx"}}}' 


Disruptive updates
 kubectl replace -f ./nginx-rc.yaml --force





Updating your application without a service outage
        kubectl rolling-update OLD_CONTROLLER_NAME ([NEW_CONTROLLER_NAME] --image=NEW_CONTAINER_IMAGE | -f NEW_CONTROLLER_SPEC)
        // Update pods of frontend-v1 using new replication controller data in frontend-v2.json.
        $ kubectl rolling-update frontend-v1 -f frontend-v2.json

        // Update pods of frontend-v1 using JSON data passed into stdin.
        $ cat frontend-v2.json | kubectl rolling-update frontend-v1 -f -

        // Update the pods of frontend-v1 to frontend-v2 by just changing the image, and switching the
        // name of the replication controller.
        $ kubectl rolling-update frontend-v1 frontend-v2 --image=image:v2

        // Update the pods of frontend by just changing the image, and keeping the old name
        $ kubectl rolling-update frontend --image=image:v2

kubectl rolling-update foo [foo-v2] --rollback



##### undoc
`kubectl expose rc my-nginx --port=80 --type=LoadBalancer`

`kubectl exec my-nginx-5j8ok -- printenv | grep SERVICE`

    KUBERNETES_SERVICE_PORT=443
    NGINXSVC_SERVICE_HOST=10.0.116.146
    KUBERNETES_SERVICE_HOST=10.0.0.1
    NGINXSVC_SERVICE_PORT=80


    $ kubectl exec my-nginx-6isf4 -- printenv | grep SERVICE
    KUBERNETES_SERVICE_HOST=10.0.0.1
    KUBERNETES_SERVICE_PORT=443
    Note there’s no mention of your Service. This is because you created the replicas before the Service. Another  disadvantage of doing this is that the scheduler might put both pods on the same machine, which will take your entire Service down if it dies. We can do this the right way by killing the 2 pods and waiting for the replication controller to recreate them. This time around the Service exists before the replicas. This will given you scheduler level Service spreading of your pods (provided all your nodes have equal capacity), as well as the right environment variables:

    curl http://$(kubectl get pod nginx -o=template -t={{.status.podIP}})
    kubectl exec curlpod -- nslookup nginxsvc




securing service
$ make keys secret KEY=/tmp/nginx.key CERT=/tmp/nginx.crt SECRET=/tmp/secret.json
$ kubectl create -f /tmp/secret.json
secrets/nginxsecret
$ kubectl get secrets
NAME                  TYPE                                  DATA
default-token-il9rc   kubernetes.io/service-account-token   1
nginxsecret           Opaque                                2



Environment Variables

When a Pod is run on a Node, the kubelet adds a set of environment variables for each active Service. This introduces an ordering problem. To see why, inspect the environment of your running nginx pods:

command: ["/bin/echo"]
    args: ["$(MESSAGE)"]


