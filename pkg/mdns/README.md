# pkg/mdns — 區域網域名稱 (mDNS) 與 registry TLS 佈建

以 mDNS 把本機發佈成 `<hostname>.local` 與服務別名 `docker-registry.local`，
並讓 Docker 能以任一名稱推送 image 到本機 registry。alias 由 systemd unit
`mdns-alias.service` (`avahi-publish -a -R`) 常駐發佈。

Registry 的 service 定義不在這裡，由
[`platform/cloud/docker-compose.yml`](../../../platform/cloud/docker-compose.yml)
擁有；本目錄只產出它消費的兩個檔案 (`registry.crt` / `registry.key`)。

## 內容

| 路徑               | 職責                                                       |
| ------------------ | ---------------------------------------------------------- |
| `_lib_mdns.sh`     | 共用變數與 helper (僅供 source，不直接執行)                |
| `setup.sh`         | Server 端：avahi 發佈 + `mdns-alias.service` + NSS 解析 + 自我驗證 |
| `gen-cert.sh`      | 產生含 SAN 的自簽憑證至 `~/.config/registry/certs/`        |
| `client-setup.sh`  | Client 端：安裝解析器 + 佈署信任憑證 (auto patch)          |
| `verify.sh`        | 端到端驗證：解析 / TLS / push-pull round trip              |

`_lib_mdns.sh` `刻意不 source` `bin/bash/settings.sh`：`client-setup.sh` 必須能被複製到
沒有 env_setup checkout 的機器上執行，而本目錄沒有任何腳本需要 `REPO_DIR`。

## 流程 (Flow)

```bash
# --- server (本機) ---
./setup.sh                      # 或 ./setup.sh --interface enp3s0
./gen-cert.sh
./client-setup.sh               # server 自己也是 client

cd ~/projects/platform/cloud
./run.sh                        # 建立 ~/.config/registry/{data,logs}
docker compose up -d registry

./verify.sh                     # 回到 pkg/mdns/
```

```bash
# --- 其他 client ---
# 只需要兩個檔案：client-setup.sh 與它唯一的相依 _lib_mdns.sh
# (verify.sh 選配，用來事後確認)
scp ubuntu-server.local:~/projects/env_setup/pkg/mdns/{client-setup.sh,_lib_mdns.sh} /tmp/

/tmp/client-setup.sh --server ubuntu-server --scp shuk@ubuntu-server.local
```

```bash
/tmp/verify.sh --server ubuntu-server   # 事後確認，同樣要 --server
```

`--server` 在非 registry 本機上`是必填`，`client-setup.sh` 與 `verify.sh` 都一樣：
預設值來自 `hostname -s`，在 server 上正確，在 client 上會指向 client 自己的名字。

macOS 上這個預設特別危險。Mac 沒設 hostname 時會回報反解出來的名稱，於是
`hostname -s` 從 `192.168.1.173` 取出 `192`，所有檢查都跑去測 `192.local`——
一個在輸出裡看起來像模像樣、但不可能成立的目標：

```console
$ ./verify.sh          # 沒給 --server 的 Mac
  ! FAIL 192.local does not resolve
  ! FAIL build probe image
  ...
```

因此 `mdns_require_server()` 在`沒有 --server 且本機沒有 registry 憑證`時`直接拒跑`，
不是警告後照做——這種失敗的症狀離病因太遠，警告會被當成雜訊略過。

推送 (兩個名稱等價，`docker-registry.local` 不綁機器名)：

```bash
docker tag projects-msghub:latest docker-registry.local:5000/msghub:latest
docker push docker-registry.local:5000/msghub:latest
# 或 ubuntu-server.local:5000/msghub:latest
```

## 關鍵決策 (Key Decisions)

- **hostname 之外只加一個服務別名，用 `avahi-publish -a -R` 常駐**。avahi 開箱即發佈
  `$(hostname -s).local`；`docker-registry.local` 讓 client 端的 tag 不綁機器名，
  日後換主機只需改 server 端。avahi 沒有 CNAME；`/etc/avahi/hosts` 看似更簡單但
  `不能`為本機自己的 IP 建 alias——它會連帶註冊 reverse PTR，與 hostname 自身的
  反解衝突，avahi 啟動時報 `Local name collision` 且靜默不發佈 (avahi/avahi#40)。
  `-R` (no-reverse) 只有 `avahi-publish` 有，因此由 `setup.sh` 寫入
  `/etc/systemd/system/mdns-alias.service`，`PartOf=avahi-daemon.service` 跟著
  avahi 一起重啟。alias 指向的 IP 依 `--interface`（或第一個 LAN 位址）決定，
  換 IP 需重跑 `setup.sh`。
- **憑證 SAN 同時涵蓋 hostname 與 alias**。`gen-cert.sh` 偵測到既有憑證缺 alias
  SAN 會自動重簽；重簽後所有 client 必須重跑 `client-setup.sh`。Linux client 的
  `certs.d` 依 `<host>:<port>` 建目錄，所以 alias 要另放一份 `ca.crt`；macOS 的
  System keychain 不分名稱，一份即可。
- **不需要 client certificate**。mTLS 是身分驗證，此處沒有 auth 需求。Client 端
  要的是`信任 server 憑證`，兩者常被混為一談。
- **憑證即自身 CA**。自簽憑證同時是 leaf 與 root，所以 client 佈署的 `ca.crt`
  和 server 用的 `registry.crt` 是同一個檔案。
- **選 certs.d 而非 insecure-registries**。`/etc/docker/certs.d/<host>:<port>/ca.crt`
  是 drop-in，dockerd `每次連線重讀`；改 `daemon.json` 則要重啟 daemon，
  而重啟會中斷該機所有 container。
- **SAN 必填，且不含 docker bridge 位址**。Go 1.15 起只有 CN 的憑證直接被拒；
  `br-*` / `docker0` 位址隨 compose project 變動，寫進 10 年效期的憑證沒有意義。
- **驗證用 `FROM scratch` 探針**。round trip 測試不能依賴 upstream pull，否則
  Docker Hub 憑證過期之類的無關因素會讓驗證失敗。

## 陷阱：本機解析得到 ≠ 佈建完成

`getent hosts <hostname>.local` 在`還沒裝 avahi 之前`就會有答案，這會讓人誤判已經完成。
成因是 systemd-resolved 會把本機 hostname 合成到`所有`介面位址：

```console
$ resolvectl mdns          # 全部 link 都是 no —— 根本沒有 mDNS
$ getent ahostsv4 ubuntu-server.local
192.168.1.200 192.168.1.173 100.127.196.58 172.18.0.1 172.17.0.1
```

兩個後果：

1. `只有本機`看得到這個名字；LAN 上其他機器什麼都解析不到。
2. 答案裡混著 `docker0` / `br-*` 位址，client 有機會挑到 bridge IP 而卡住。

`verify.sh` 因此`不以「解析得到」作為判準`，而是檢查有無 LAN-routable IPv4、
是否混入 bridge 位址、以及 `nsswitch.conf` 有沒有 mdns source；命中任一項會標示
`degraded`，不會回報 all passed。

avahi 與 systemd-resolved 可以共存：resolved 的 mDNS 預設關閉，port 5353 由 avahi 獨佔。

## 已知限制 (Limits)

- **mDNS 不跨網段**。`.local` 走 multicast，只在同一個 L2 broadcast domain 有效。
  Tailscale 對端解析不到，需改用 MagicDNS 名稱或 IP —— 憑證 SAN 已含各介面 IP。
- **同網段雙 NIC 會兩個位址都發佈**，client 取先到的回應。用
  `setup.sh --interface <ifname>` 釘住一個。
- **Registry 無 auth**。任何能連到 port 5000 的人都能 push 與 pull。
  存取控制由網路邊界負責，不由 registry 負責。
- **`--fetch` 是 trust-on-first-use**。憑證從它自己要驗證的那條連線取得；
  必須把印出的 SHA-256 與 server 端 `gen-cert.sh` 的輸出對照。

## 疑難排解 (Troubleshooting)

| 症狀                                                        | 原因                                                                 |
| ----------------------------------------------------------- | -------------------------------------------------------------------- |
| `verify.sh` 一連五個 `FAIL build/push/pull`                 | 本機 docker daemon 沒在跑（OrbStack / Docker Desktop 未啟動）；現在會直接 `die` 提示 |
| `trust store holds a different certificate than ... serves` | server 重簽了憑證 (`gen-cert.sh`)；client 重跑 `client-setup.sh --server <host>` |
| `docker-registry.local does not resolve`                    | server 端 `mdns-alias.service` 沒在跑：`systemctl status mdns-alias`，或重跑 `setup.sh` |
| avahi log `Static host name ...: Local name collision`       | `/etc/avahi/hosts` 殘留 alias 行（舊版 setup.sh）；重跑 `setup.sh` 會移除 |
| `dial tcp: lookup ...local: no such host`                   | client 沒裝 `libnss-mdns`，或 `/etc/nsswitch.conf` 沒有 mdns source  |
| `x509: certificate signed by unknown authority`             | `ca.crt` 沒放進 `/etc/docker/certs.d/<host>:5000/`（`:5000` 不可省） |
| `x509: cannot validate ... because it doesn't contain any IP SANs` | 用 IP 連線但憑證 SAN 沒有該 IP；重跑 `gen-cert.sh --force`     |
| `http: server gave HTTP response to HTTPS client`           | registry 沒掛上 TLS 環境變數，或 `certs` bind mount 是空的           |
| `authentication required`                                   | 這是 Docker Hub 的錯，不是本 registry；`docker logout` 清掉失效 token |
