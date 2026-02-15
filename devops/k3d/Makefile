CLUSTER_NAME := dev-workspace
NAMESPACE := dev

## 叢集管理 (Cluster Management)
cluster-create:    ## 建立 k3d 叢集
	k3d cluster create --config k3d-config.yaml

cluster-delete:    ## 刪除 k3d 叢集
	k3d cluster delete $(CLUSTER_NAME)

cluster-start:     ## 啟動 k3d 叢集
	k3d cluster start $(CLUSTER_NAME)

cluster-stop:      ## 停止 k3d 叢集
	k3d cluster stop $(CLUSTER_NAME)

cluster-list:      ## 列出所有 k3d 叢集
	k3d cluster list

## 工作空間 (Workspace)
setup:             ## 套用所有 manifests
	kubectl apply -f manifests/namespace.yaml
	kubectl apply -f manifests/workspace-pod.yaml
	kubectl wait --for=condition=Ready pod/workspace -n $(NAMESPACE) --timeout=120s
	@echo "✅ Workspace ready! Run: make debug"

teardown:          ## 刪除所有資源
	kubectl delete -f manifests/ --ignore-not-found

## 除錯 (Debug)
debug:             ## 進入 workspace 容器除錯
	kubectl exec -it workspace -n $(NAMESPACE) -- bash

attach:            ## Attach 到 workspace 容器
	kubectl attach -it workspace -n $(NAMESPACE)

logs:              ## 查看 workspace logs
	kubectl logs workspace -n $(NAMESPACE) -f

## 新功能容器 (Feature Container)
feature:           ## 建立新功能容器 (用法: make feature NAME=my-feature)
	@if [ -z "$(NAME)" ]; then echo "❌ 請指定 NAME, 例如: make feature NAME=my-feature"; exit 1; fi
	sed 's/FEATURE_NAME/$(NAME)/g' manifests/feature-pod.yaml | kubectl apply -f -
	kubectl wait --for=condition=Ready pod/feature-$(NAME) -n $(NAMESPACE) --timeout=120s
	@echo "✅ Feature container ready! Run: make feature-debug NAME=$(NAME)"

feature-debug:     ## 進入功能容器除錯 (用法: make feature-debug NAME=my-feature)
	kubectl exec -it feature-$(NAME) -n $(NAMESPACE) -- bash

feature-delete:    ## 刪除功能容器 (用法: make feature-delete NAME=my-feature)
	kubectl delete pod feature-$(NAME) -n $(NAMESPACE) --ignore-not-found

## 狀態 (Status)
status:            ## 顯示所有 Pod 狀態
	kubectl get pods -n $(NAMESPACE) -o wide

help:              ## 顯示此說明
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
.PHONY: cluster-create cluster-delete cluster-start cluster-stop cluster-list setup teardown debug attach logs feature feature-debug feature-delete status help
