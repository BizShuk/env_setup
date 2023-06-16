#!/bin/bash


### Kube-prometheus-stack Installation
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack

kubectl port-forward svc/kube-prometheus-stack-prometheus 9090
curl http://localhost:9090