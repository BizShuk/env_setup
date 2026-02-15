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

## 工作空間 (Workspace) — 需指定 PROJECT=<project_name>
setup:             ## 部署 workspace pod (用法: make setup PROJECT=env_setup)
	@if [ -z "$(PROJECT)" ]; then echo "❌ 請指定 PROJECT, 例如: make setup PROJECT=env_setup"; exit 1; fi
	kubectl apply -f manifests/namespace.yaml
	sed 's/PROJECT_NAME/$(PROJECT)/g' manifests/workspace-pod.yaml | kubectl apply -f -
	kubectl wait --for=condition=Ready pod/workspace-$(PROJECT) -n $(NAMESPACE) --timeout=120s
	@echo "✅ Workspace ready! Run: make debug PROJECT=$(PROJECT)"

teardown:          ## 刪除所有資源
	kubectl delete -f manifests/namespace.yaml --ignore-not-found

## 除錯 (Debug) — 需指定 PROJECT=<project_name>
debug:             ## 進入 workspace 容器除錯 (用法: make debug PROJECT=env_setup)
	@if [ -z "$(PROJECT)" ]; then echo "❌ 請指定 PROJECT, 例如: make debug PROJECT=env_setup"; exit 1; fi
	kubectl exec -it workspace-$(PROJECT) -n $(NAMESPACE) -- bash

attach:            ## Attach 到 workspace 容器
	@if [ -z "$(PROJECT)" ]; then echo "❌ 請指定 PROJECT"; exit 1; fi
	kubectl attach -it workspace-$(PROJECT) -n $(NAMESPACE)

logs:              ## 查看 workspace logs
	@if [ -z "$(PROJECT)" ]; then echo "❌ 請指定 PROJECT"; exit 1; fi
	kubectl logs workspace-$(PROJECT) -n $(NAMESPACE) -f

## 新功能容器 (Feature Container) — 需指定 PROJECT 與 NAME
feature:           ## 建立全新功能容器 (用法: make feature PROJECT=env_setup NAME=auth-v2)
	@if [ -z "$(PROJECT)" ] || [ -z "$(NAME)" ]; then echo "❌ 用法: make feature PROJECT=env_setup NAME=my-feature"; exit 1; fi
	@echo "🗑️  Removing existing feature-$(NAME) if any..."
	-kubectl delete pod feature-$(NAME) -n $(NAMESPACE) --ignore-not-found --wait=true 2>/dev/null
	sed 's/FEATURE_NAME/$(NAME)/g; s/PROJECT_NAME/$(PROJECT)/g' manifests/feature-pod.yaml | kubectl apply -f -
	kubectl wait --for=condition=Ready pod/feature-$(NAME) -n $(NAMESPACE) --timeout=120s
	@echo "✅ Brand new feature container ready! Run: make feature-debug NAME=$(NAME)"

feature-debug:     ## 進入功能容器除錯 (用法: make feature-debug NAME=my-feature)
	kubectl exec -it feature-$(NAME) -n $(NAMESPACE) -- bash

feature-delete:    ## 刪除功能容器 (用法: make feature-delete NAME=my-feature)
	kubectl delete pod feature-$(NAME) -n $(NAMESPACE) --ignore-not-found

## 狀態 (Status)
status:            ## 顯示所有 Pod 狀態
	kubectl get pods -n $(NAMESPACE) -o wide --show-labels

help:              ## 顯示此說明
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-18s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
.PHONY: cluster-create cluster-delete cluster-start cluster-stop cluster-list setup teardown debug attach logs feature feature-debug feature-delete status help
