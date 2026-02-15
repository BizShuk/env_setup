# K3d 開發工作空間 (K3d Dev Workspace)

使用 k3d 在本地快速建立 Kubernetes 開發環境，支援容器除錯與新功能容器建立。

## 前置需求 (Prerequisites)

```bash
brew install k3d kubectl
# 選用 (optional)
brew install k9s
```

確認 Docker 正在運行（Colima 或 Docker Desktop）。

## 快速開始 (Quick Start)

```bash
# 1. 建立叢集
make cluster-create

# 2. 部署 workspace pod
make setup

# 3. 進入容器除錯
make debug
```

## 常用指令 (Common Commands)

| 指令                  | 說明                 |
| --------------------- | -------------------- |
| `make cluster-create` | 建立 k3d 叢集        |
| `make cluster-delete` | 刪除 k3d 叢集        |
| `make cluster-start`  | 啟動叢集             |
| `make cluster-stop`   | 停止叢集             |
| `make setup`          | 部署 workspace pod   |
| `make teardown`       | 清除所有資源         |
| `make debug`          | 進入 workspace bash  |
| `make attach`         | Attach stdout/stderr |
| `make logs`           | 查看 logs            |
| `make status`         | 顯示 Pod 狀態        |

## 新功能容器 (Feature Containers)

```bash
# 建立新功能容器
make feature NAME=auth-v2

# 進入功能容器
make feature-debug NAME=auth-v2

# 刪除功能容器
make feature-delete NAME=auth-v2
```

每個功能容器都是獨立的 Pod，掛載相同的 `/workspace` 目錄。

## 目錄結構

```
devops/k3d/
├── k3d-config.yaml       # 叢集設定
├── Makefile              # 快捷指令
├── manifests/
│   ├── namespace.yaml    # dev namespace
│   ├── workspace-pod.yaml # 主工作容器
│   └── feature-pod.yaml  # 功能容器範本
└── README.md             # 本文件
```

## 注意事項 (Notes)

- Volume 掛載：本地 `env_setup` → 容器內 `/workspace`
- Workspace Pod 使用 `sleep infinity` 保持運行
- Feature Pod 使用 `sed` 替換 `FEATURE_NAME` 佔位符
- 預設關閉 Traefik ingress controller
