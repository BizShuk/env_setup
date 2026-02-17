# Chat Summary: Monitoring System & Environment Update

**Created**: 2026-02-18
**Topic**: Monitoring System Expansion & Local DNS Optimization
**Status**: Completed (Staged)

## 🛠️ 更新內容摘要 (Summary)

本次更新主要集中於擴展時間序列數據庫 (Time Series Database, TSDB) 的支援，並完善開發環境在不同作業系統下的網路配置。

### 1. 監控系統增強 (Monitoring System Enhancements)

- 新增 OpenTSDB 支援:
    - 在 `docker-compose.yaml` 中導入了 `petergrace/opentsdb-docker:latest` 鏡像 (Image)。
    - 配置了持久化磁碟卷 (Persistent Volume) `opentsdb_data` 於 `/data/hbase`。
    - **新增文件**: `devops/README.opentsdb.md` 提供 API 使用範例與 UI 訪問資訊。
- Bosun 告警框架 (Alerting Framework) 整合:
    - 在 `docker-compose.yaml` 中新增了 `bosun` 服務，對應埠號為 `8070`。
    - **重要提示**: Bosun 專案已進入封存狀態 (Archived)，且其 Docker 鏡像僅支援 `amd64` 架構，不支援 `arm64` (如 Apple Silicon MacBook)。
    - **新增設定檔**: `devops/grafana/bosun/bosun.conf`，定義了與 OpenTSDB 的連線資訊。
    - **Grafana 插件**: 導入了 `bosun-grafana-app` 插件及其完整源碼與截圖。

### 2. 網路與 DNS 配置 (Network & DNS Configuration)

- 本地 DNS 解析 (Local DNS Resolution):
    - 更新 `devops/README.core_dns.md`，加入了更詳盡的作業系統層級配置說明。
    - **macOS**: 增加 `/etc/resolver/test` 設定方式。
    - **Ubuntu**: 增加 `systemd-resolved` 配置說明 (使用 `test-domain.conf`)。
    - **Colima 提示**: 加入了關於 `grpc` 網路驅動器的注意事項，以支援 UDP 轉發。

### 3. 基礎設施與工具優化 (Infrastructure & Tooling)

- Docker Compose 重構:
    - 統一了 `docker-compose.yaml` 中的縮進格式。
    - 更新了「埠號衝突規則 (Port Conflict Notes)」，納入了 Grafana (3000), OpenTSDB (4242) 與 Bosun (8040 -> 8070)。
    - 修正並啟用了 `bosun_data` 持久化磁碟卷。
- README 文件維護:
    - 批次更新了所有服務的 README (包括 MySQL, InfluxDB, Prometheus, Node Exporter, Pushgateway)，確保格式一致性。
- VS Code 環境:
    - README 文件維護:
    - 批次更新了所有服務的 README (包括 MySQL, InfluxDB, Prometheus, Node Exporter, Pushgateway)，確保格式一致性。

- VS Code 環境:
    - 更新了 `bin/vscode/settings.json` 以同步編輯器設定。

---

## 📂 變更檔案清單 (Changed Files)

### 新增 (New)

- `devops/README.opentsdb.md`
- `devops/grafana/bosun/bosun.conf`
- `devops/grafana/plugins/bosun-grafana-app/*`

### 修改 (Modified)

- `devops/docker-compose.yaml`
- `devops/README.core_dns.md`
- `devops/README.md`
- `bin/vscode/settings.json`
- `devops/README.influxdb.md`
- `devops/README.mysql.md`
- `devops/README.node_exporter.md`
- `devops/README.prometheus.md`
- `devops/README.pushgateway.md`
