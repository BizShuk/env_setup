#!/bin/bash

### Kind installation
go install sigs.k8s.io/kind@v0.14.0


### Create cluster with config
kind create cluster --config kind-single-control-panel.yaml

### Load image to cluster
IMAGE_NAME=""
KIND_CLUSTER_NAME="mc1"
kind load docker-image ${IMAGE_NAME} ${KIND_CLUSTER_NAME}

### kind Debug
kind export logs    # export all container log out

### prune if volume problem from docker
docker volume ls -f dangling=true