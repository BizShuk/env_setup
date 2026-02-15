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
make feature PROJECT=env_setup NAME=auth-v2

# 進入功能容器
make feature-debug NAME=auth-v2

# 刪除功能容器
make feature-delete NAME=auth-v2
```

每個功能容器都是獨立的 Pod，檔案複製自 `~/projects/<project>` 但與 host 隔離。

## VS Code Remote Development（遠端開發連線）

有三種方式可以用 VS Code 連進 k3d 容器進行開發：

### 方法一：Kubernetes Extension（推薦，最簡單）

1. **安裝擴充套件**：
   - [Kubernetes](https://marketplace.visualstudio.com/items?itemName=ms-kubernetes-tools.vscode-kubernetes-tools)

2. **操作步驟**：
   - 打開 VS Code 側邊欄的 **Kubernetes** 面板
   - 展開 `dev-workspace` → **Namespaces** → `dev` → **Pods**
   - 右鍵點選 Pod（例如 `workspace-env_setup`）
   - 選擇 **Attach Visual Studio Code**
   - VS Code 會開啟新視窗，直接連進容器
   - 打開資料夾 `/home/shuk/projects/<project_name>`

> 此方法不需要安裝 SSH，直接透過 kubectl API 通道連線。

### 方法二：kubectl + VS Code Terminal

最直接的方式，不需要額外設定：

```bash
# 在 VS Code 的 Terminal 直接執行
make debug PROJECT=env_setup

# 你現在已經在容器內
cd /home/shuk/projects/env_setup
```

### 方法三：SSH Remote（進階，適合長期使用）

在容器內安裝 SSH server，用 VS Code Remote-SSH 擴充套件連入：

1. **進入容器並安裝 SSH**：

```bash
make debug PROJECT=env_setup

# 在容器內執行
apt-get update && apt-get install -y openssh-server
mkdir -p /run/sshd
echo 'root:devpass' | chpasswd
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
/usr/sbin/sshd
```

2. **Port Forward（另開一個 terminal）**：

```bash
kubectl port-forward pod/workspace-env_setup -n dev 2222:22
```

3. **VS Code Remote-SSH 連線**：
   - `Cmd+Shift+P` → **Remote-SSH: Connect to Host**
   - 輸入 `root@localhost -p 2222`（密碼：`devpass`）
   - 打開 `/home/shuk/projects/env_setup`

> [!TIP]
> 方法一最方便（zero config），方法三最完整（支援 extensions 在遠端執行）。
> 建議先用方法一，需要更完整的開發體驗再升級到方法三。

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

- 檔案隔離：host `~/projects/<project>` 的副本複製到容器 `/home/shuk/projects/<project>`，修改不影響原始檔案
- Workspace Pod 使用 `sleep infinity` 保持運行
- Feature Pod 使用 `sed` 替換 `FEATURE_NAME` / `PROJECT_NAME` 佔位符
- 預設關閉 Traefik ingress controller
