

1. download kubectl 
2. set "export KUBECONFIG="config path" "

cmd

kubectl get po
kubectl get rc
kubectl get se

kubectl config use_context $namespace
kubectl create -f $yaml_file
kubectl delete -f $yaml_file
