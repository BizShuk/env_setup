# Disk Analysis, I/O Benchmarking & Tuning Reference

本文件提供 macOS 與 Ubuntu (Linux) 之磁碟空間與裝置分析、I/O 基準測試（Benchmark）、傳輸協定檢視，以及核心佇列與檔案系統調校的完整參考。

---

## 1. I/O 效能指標與瓶頸判讀 (Key Metrics & Bottlenecks)

- **核心指標**：
    - **Throughput (MB/s)**：大檔循序讀寫速率，受限於介面頻寬（PCIe / SATA / USB）、快取大小與媒體持續寫入速度。
    - **IOPS (Input/Output Operations Per Second)**：小區塊（常見 4 KiB）隨機讀寫能力，決定資料庫、編譯、系統回應與大量小檔操作的體感速度。
    - **Latency (`await` / `r_await` / `w_await`)**：單次 I/O 從進入排程到完成的平均耗時（ms）。當 `%util` 接近 100% 且 `await` 飆升，代表裝置已飽和。
    - **Queue Depth (`aqu-sz` / `queue_depth`)**：同時在途（in-flight）的 I/O 請求數。NVMe 可吃滿高佇列深度（`QD=32~128+`）；低階或單佇列裝置在深佇列下只會拉高延遲。
- **常見效能懸崖**：
    - **SLC Cache 耗盡**：TLC/QLC SSD 在連續寫入超過 SLC 快取容量後，寫入速度會驟降至原生顆粒速度。
    - **Thermal Throttling**：NVMe 或外接盒過熱時會主動降速保護，需同時觀察 SMART 溫度與持續寫入曲線。
    - **Sync / `fsync` 放大**：頻繁小筆同步寫入會把高頻寬裝置打成低 IOPS 瓶頸，應同時檢視硬體 `cache_type` 與應用層批次落盤策略。

---

## 2. 磁碟空間與儲存裝置分析 (Disk Analysis)

### 2.1 裝置拓撲與傳輸介面探測

- **Repo 統一工具（跨 macOS / Ubuntu）**：
    ```bash
    # 探測所有實體磁碟之 DEV, TRAN, MODEL, SIZE, MOUNTS 與區塊/快取屬性
    pnpm run run:io:probe
    # 或直接執行
    ./scripts/io/probe.sh

    # 檢視 Root 分割區、掛載點與實體磁碟清單
    pnpm run run:system:disk
    ```
- **Ubuntu / Linux 原生檢查**：
    ```bash
    lsblk -o NAME,MODEL,TRAN,SIZE,TYPE,FSTYPE,MOUNTPOINT,DISC-GRAN
    df -h -x tmpfs -x devtmpfs -x squashfs
    df -i   # 檢查 inode 是否耗盡（空間未滿但無法建檔時必查）
    ```
- **macOS 原生檢查**：
    ```bash
    diskutil list physical
    diskutil info disk0
    system_profiler SPNVMeDataType SPUSBDataType SPStorageDataType
    df -h /System/Volumes/Data
    ```

### 2.2 磁碟空間用量分析 (Space Usage Analysis)

- **全機可回收空間掃描（搭配 `dux` / `disk-analyze`）**：
    ```bash
    dux scan --min-size 50MB
    dux analyze --top 20
    ```
- **指定目錄快速下鑽（排除跨掛載點）**：
    ```bash
    # Linux
    sudo du -xhd 1 /var | sort -hr | head -n 20

    # macOS
    du -hd 1 ~/Library | sort -hr | head -n 20
    ```

### 2.3 外接媒體真偽與完整性驗證 (F3 Verification)

- 針對隨身碟、記憶卡或新購入外接碟，以 `f3write` / `f3read` 驗證實際可用容量與壞軌：
    ```bash
    pnpm run run:system:disk-verify -- /Volumes/<USB_DRIVE>
    # 或直接執行
    ./scripts/system/disk_verify.sh /Volumes/<USB_DRIVE>
    ```

---

## 3. 磁碟 I/O 基準測試實務 (Disk I/O Benchmarking)

### 3.1 Repo 內建快速基準評測 (`bench.sh`)

同時測試 **循序寫入 (Sequential Write)**、**4K 同步寫入 (Sync Write IOPS / Latency)**、**循序讀取 (Sequential Read)** 與 **4K 隨機讀取 (Random Read IOPS / Latency)**：

```bash
# 對預設 /tmp 進行評測（預設 64 MiB 循序樣本、50 次 4K 操作）
pnpm run run:io:bench

# 指定目標掛載目錄、測試大小與 4K 操作次數
./scripts/io/bench.sh -d /mnt/mydrive -s 256 -o 200

# 探測裝置同時對指定目錄執行評測
./scripts/io/probe.sh --bench -d /mnt/mydrive -s 256 -o 200
```

### 3.2 排除 Page Cache 干擾原則

- **Linux 冷讀取**：先刷寫髒頁並釋放 Page Cache，或使用 `O_DIRECT`（若檔案系統支援）：
    ```bash
    sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
    ```
- **macOS 冷讀取**：先清除記憶體檔案快取再讀檔：
    ```bash
    sudo purge
    ```
- **真實寫入（含落盤）**：必須加上 `conv=fsync`（寫完刷盤）或 `oflag=sync` / `direct`，避免只測到寫入 RAM Page Cache 的虛高速度。

### 3.3 `fio` 標準基準測試範例（推薦用於深入剖析）

- **1M 循序讀寫吞吐量（Sequential Throughput, `QD=8`）**：
    ```bash
    fio --name=seq_test --directory=/path/to/testdir --size=1G \
        --bs=1M --rw=readwrite --ioengine=posixaio --direct=1 \
        --iodepth=8 --numjobs=1 --time_based --runtime=30 --group_reporting \
        --unlink=1
    ```
    *(註：Linux 可將 `--ioengine=posixaio` 改為 `libaio` 或 `io_uring`；若目標為 Linux `exfat` 不支援 `O_DIRECT`，請改用 `--direct=0 --fsync=1`)*

- **4K 隨機讀寫 IOPS 與延遲分佈（Random 4K IOPS & Latency, `QD=1` 與 `QD=32`）**：
    ```bash
    # QD=1 測單執行緒真實反應延遲 (p95 / p99 latency)
    fio --name=rand4k_qd1 --directory=/path/to/testdir --size=256M \
        --bs=4k --rw=randrw --rwmixread=70 --direct=1 \
        --iodepth=1 --numjobs=1 --time_based --runtime=30 --group_reporting \
        --unlink=1
    ```

### 3.4 `dd` 單執行緒快速健檢

```bash
# 真實落盤寫入測試
dd if=/dev/zero of=/path/to/testdir/.io_test bs=4M count=128 conv=fsync

# 冷讀取測試（先執行 drop_caches 或 sudo purge）
dd if=/path/to/testdir/.io_test of=/dev/null bs=4M

# 清理測試檔
rm -f /path/to/testdir/.io_test
```

### 3.5 即時 I/O 監測指令

- **Ubuntu / Linux**：
    - `iostat -xz <dev> 1`：觀察 `r/s`、`w/s`、`rkB/s`、`wkB/s`、`r_await`、`w_await`、`aqu-sz`（平均佇列長度）、`%util`。
    - `sudo iotop -oP`：定位當下正在產生大量讀寫的行程。
    - `cat /proc/pressure/io`：檢視 Linux PSI (Pressure Stall Information) I/O 阻塞比例。
- **macOS**：
    - `iostat -d -w 1`：觀察每顆磁碟的 `KB/t`（單次傳輸大小）、`tps`、`MB/s`。
    - `sudo fs_usage -w -f diskio`：追蹤即時磁碟 I/O 的具體行程與系統呼叫耗時。

---

## 4. 傳輸協定、硬體對齊與快取 (Transport, Alignment & Cache)

- **介面與協定差異**：
    - **NVMe (PCIe)**：多佇列原生支援（最高 64K queues），低延遲、高 IOPS。
    - **SATA (AHCI)**：單佇列最高 `NCQ depth = 32`，實際吞吐上限約 `550–600 MB/s`。
    - **USB 儲存協定（UAS vs BOT）**：
        - `Driver=uas`（USB Attached SCSI）：支援多佇列（如 `queue_depth=30`）與非同步指令，能跑滿 USB 3.x 頻寬（5 Gbps 實測循序可達 ~`450 MB/s`，10 Gbps 可達 ~`950+ MB/s`）。
        - `Driver=usb-storage`（BOT, Bulk-Only Transport）：常見於平價隨身碟或舊橋接晶片，`queue_depth` 常受限為 `1~2`，高併發或頻繁 `fsync` 會有顯著延遲。
        - Linux 檢查：`lsusb -t`（看 `Driver=` 與速率 `480M` / `5000M` / `10000M`）、`/sys/block/<dev>/device/queue_depth`、`/sys/bus/usb/devices/<port>/speed`。
- **實體區塊對齊 (Alignment)**：
    - 檢查 `/sys/block/<dev>/queue/physical_block_size` 與 `optimal_io_size`。
    - 分割區起點與邊界應對齊 `1 MiB`（若裝置回報 `optimal_io_size = 4194304` 則對齊 `4 MiB`），避免跨實體頁觸發 Read-Modify-Write (RMW) 寫入放大。
- **裝置寫入快取 (`cache_type`)**：
    - Linux 檢查：`/sys/block/<dev>/device/scsi_disk/*/cache_type`（`write back` vs `write through`）。
    - `write back` 延遲低但依賴正確 `FLUSH` 與供電穩定；無快取或 `write through` 裝置在小區塊同步寫入時延遲較高。

---

## 5. Linux Kernel I/O Queue 與 VM 調校

### 5.1 Block Queue (`/sys/block/<dev>/queue/`)

- **`scheduler`（I/O 排程器）**：
    - `none`：建議用於 NVMe、高效能 SSD 與 UAS 裝置，避免多餘的請求排序與鎖競爭開銷。
    - `mq-deadline`：適合 HDD 或混合讀寫需要保證最大延遲上限的場景。
    - `bfq`：適合慢速裝置的桌面互動優先排程，不適合追求高 IOPS 的伺服器負載。
- **`read_ahead_kb`（與 `/sys/block/<dev>/bdi/read_ahead_kb`）**：
    - 控制循序讀取預讀視窗（預設常為 `128` KiB）。
    - 大檔循序讀取為主的高頻寬儲存（如媒體串流、備份碟）可調大至 `1024`–`8192` KiB。
    - 隨機小檔讀取（如資料庫）應維持小值（`64`–`128` KiB），避免預讀過多無用資料造成讀取放大（read amplification）。
- **`rotational`**：
    - SSD / Flash 應為 `0`，HDD 為 `1`。部分 USB 橋接晶片未回報非旋轉媒體屬性時核心會誤設為 `1`，可用 `udev` 規則依 `idVendor`/`idProduct` 修正為 `0`。
- **`nr_requests` 與 `max_sectors_kb`**：
    - `nr_requests` 控制 block layer 佇列請求上限；`max_sectors_kb` 決定單次 I/O 最大傳輸大小（受限於 `max_hw_sectors_kb`）。

### 5.2 Dirty Page Writeback (`sysctl`)

- 預設 `vm.dirty_background_ratio` / `vm.dirty_ratio` 依總記憶體百分比計算；在大記憶體主機上會累積過多未刷寫資料，導致慢速碟或 USB 裝置在 `sync` / `umount` 時長時間卡頓。
- 建議改用絕對位元組上限讓背景寫回平滑排水（設定 `*_bytes` 會自動覆蓋對應 `*_ratio`）：
    - `vm.dirty_background_bytes`（例如 `8388608` = 8 MiB 或 `16777216` = 16 MiB）：達到此閾值即喚醒背景 flusher 開始寫回。
    - `vm.dirty_bytes`（例如 `33554432` = 32 MiB 或 `67108864` = 64 MiB）：達到此閾值時強制寫入行程同步節流，防止記憶體被髒頁塞爆。

---

## 6. 檔案系統與掛載調校 (Filesystem & Mount Options)

- **`noatime` / `relatime`**：掛載加上 `noatime`（或至少 `relatime`）可消除每次讀取檔案時更新 access time 產生的額外 metadata 寫入。
- **TRIM / Discard 策略**：
    - 避免在一般消費級 SSD 上掛載同步 `discard`（大量刪檔時可能引發延遲尖峰）；改用定期排程 `fstrim`（如 `systemctl enable --now fstrim.timer`）。
- **常見檔案系統特性**：
    - **`ext4`**：通用穩定；預設 `data=ordered` 兼顧一致性與效能，高併發小檔可留意 journal 裝置負擔。
    - **`xfs`**：多 Allocation Group 設計，在高併發多執行緒讀寫與大檔吞吐上表現優異。
    - **`exfat`**：跨平台（macOS / Windows / Linux）免權限問題，但不具 journaling 與 POSIX 權限；**Linux kernel `exfat` 驅動不支援 `O_DIRECT`**（傳入 `iflag=direct` / `oflag=direct` 會回傳 `Invalid input`），測試時須改用 buffered I/O 搭配冷快取或 `conv=fsync`。
    - **`APFS` (macOS)**：支援 Copy-on-Write、Snapshots 與 Clone files；大量本地 Time Machine 快照（`tmutil listlocalsnapshots /`）或高碎片化時可能影響寫入與空間釋放速度。
