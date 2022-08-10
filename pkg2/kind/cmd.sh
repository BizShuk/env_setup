#!/bin/bash

### Kind installation
go install sigs.k8s.io/kind@v0.14.0


### Create cluster with config
kind create cluster --config kind-single-control-panel.yaml


### kind Debug
kind export logs    # export all container log out