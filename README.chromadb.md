# ChromaDB 服務使用指南 (ChromaDB Service Guide)

本專案使用 Docker Compose 來管理與運行 ChromaDB 向量資料庫。

## 1. 系統依賴 (Dependencies)

在啟動服務之前，請確保您的系統已安裝 Docker 以及 Docker Compose。
如果您使用的是 macOS 且尚未安裝 `docker-compose`，可以透過 Homebrew 進行安裝：

```bash
brew install docker-compose
```

*(註：如果系統環境不同，您可能會需要使用 `docker compose`，本專案依賴安裝獨立的 `docker-compose` 工具)*

## 2. 啟動服務 (Start Service)

ChromaDB 的設定已整合在 `devops/docker-compose.yaml` 中。您可以使用以下指令來單獨啟動 ChromaDB 服務，並在背景執行：

```bash
docker-compose -f devops/docker-compose.yaml up -d chromadb
```

這個指令會：
- 建立並啟動名為 `chromadb` 的容器
- 建立名為 `chromadb_data` 的 Volume 供資料持久化使用
- 將容器的連接埠映射到主機的 `localhost:8000`

## 3. 存取服務與驗證 (Access & Verification)

當服務順利啟動後，ChromaDB 將會監聽在主機的 `8000` port。您可以透過任何 HTTP 客戶端存取 ChromaDB API。

最簡單的驗證方式是使用 `curl` 檢查伺服器的心跳 (Heartbeat) 狀態，確認服務是否存活：

```bash
curl http://localhost:8000/api/v2/heartbeat
```

如果服務正常運作，您預期會收到一個包含時間戳記的 JSON 回應：
```json
{"nanosecond heartbeat": 169xxxxxx00000000}
```

接著，您就可以將 `http://localhost:8000` 提供給您的應用程式 (如 Python 或 Node.js 的 Chroma Client) 作為伺服器連線位址。

## 4. 停止服務 (Stop Service)

若要停止服務，可以使用以下指令：

```bash
docker-compose -f devops/docker-compose.yaml stop chromadb
```

若想將容器完全移除（此舉不會刪除持久化的 Volume 資料）：
```bash
docker-compose -f devops/docker-compose.yaml rm -f chromadb
```
