# Dev Container — Docker Compose 整合

將 `devops/docker-compose.yaml` 基礎建設服務 (Infrastructure Services) 與 Dev Container 整合，透過 Docker Compose [profiles](https://docs.docker.com/compose/how-tos/profiles/) 實現按需啟動。

> [!NOTE]
> 此 Dev Container 僅供**測試用途** — 用來驗證 setup scripts 是否正確運行，**不關聯任何服務層級或正式專案**。

## 架構概述

Dev Container 使用 `dockerComposeFile` 搭配 profiles：

- **預設只啟動 workspace 容器**（開發環境）
- **按需啟動基礎建設服務**（prometheus、grafana 等）
- 所有容器共用 `inf_network`，互相可連線

### 檔案結構

```tree
.devcontainer/
├── devcontainer.json      # VS Code Dev Container 設定
├── Dockerfile             # workspace 容器 (Ubuntu 24.04, user: shuk)
├── docker-compose.yaml    # 整合 compose 檔（workspace + infra services）
└── README.md              # 本文件
```

## 容器啟動行為

| 情境                                             | 啟動的服務                                       |
| ------------------------------------------------ | ------------------------------------------------ |
| VS Code「Reopen in Container」                   | 僅 `workspace`（開發環境）                       |
| `--profile infra`                                | `workspace` + 全部基礎建設服務                   |
| `--profile monitoring`                           | `workspace` + prometheus + pushgateway + grafana |
| `--profile database`                             | `workspace` + mysql + influxdb                   |
| `--profile dns`                                  | `workspace` + coredns                            |
| 組合如 `--profile monitoring --profile database` | `workspace` + 指定 profile 的服務                |

> [!IMPORTANT]
> 所有基礎建設服務的 username/password 保持不變，與原本 `devops/docker-compose.yaml` 完全一致。

## 使用方式

### 1. 啟動開發環境

在 VS Code 中執行 **Reopen in Container**，僅啟動 workspace。

### 2. 啟動基礎建設服務

在 `.devcontainer/` 目錄下：

```bash
# 僅 monitoring（prometheus + pushgateway + grafana）
docker-compose --profile monitoring up -d

# 僅 database（mysql + influxdb）
docker-compose --profile database up -d

# 僅 DNS
docker-compose --profile dns up -d

# 全部基礎建設
docker-compose --profile infra up -d

# 組合使用
docker-compose --profile monitoring --profile database up -d
```

## 驗證步驟

1. **Reopen in Container** → `whoami` 應回傳 `shuk`
2. `ls ~/projects/env_setup` → 確認 workspace 掛載正確
3. `docker-compose --profile monitoring up -d` → 確認個別 profile 可單獨啟動
4. `docker-compose --profile infra up -d` → 確認全部服務可一次啟動

## Port 對照表

| Service     | Port            |
| ----------- | --------------- |
| Prometheus  | 9090            |
| Pushgateway | 9091            |
| MySQL       | 3306            |
| InfluxDB    | 8086            |
| Grafana     | 3000            |
| CoreDNS     | 10053 (UDP/TCP) |

> [!NOTE]
> CoreDNS 使用 10053 埠位 (Port)，因為 53 埠位已被 Colima 佔用。
