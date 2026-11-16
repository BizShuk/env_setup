---
name: system-evaluation
description: Use when evaluating, probing, diagnosing, or benchmarking a macOS or Ubuntu/Linux system — inspecting hardware specs (CPU, memory, GPU, disk, USB, display, network, audio), analyzing CPU/memory/swap pressure or macOS wakeup/energy drain, running disk space and transport analysis, or running disk I/O benchmarks and kernel/filesystem tuning. Triggers on "system evaluation", "system probe", "hardware info", "system benchmark", "disk benchmark", "disk analysis", "disk knowledge", "disk io", "io tuning", "read_ahead_kb", "dirty_bytes", "io scheduler", "uas", "iops", "fio", "iostat", "energy drain", "wakeup storm", "系統評估", "硬體檢測", "系統效能", "磁碟分析", "磁碟測速", "磁碟調校", "I/O 調校", "耗電分析".
---

# system-evaluation

## Overview

提供跨 **macOS** 與 **Ubuntu (Linux)** 的全機硬體探測、系統資源瓶頸診斷、耗電/喚醒分析，以及**磁碟空間分析、I/O 基準測試與核心調校**的標準化評估流程。

評估分為四個核心維度：
1. **全機硬體與系統規格探測 (System & Hardware Probe)**：OS、CPU、Memory、GPU、Disk、USB、Display、Network、Input、Audio。
2. **運算、記憶體與耗電瓶頸診斷 (Compute, Memory & Energy Diagnostics)**：CPU 負載與排程、RAM / Swap 壓力、Linux PSI、macOS 喚醒風暴 (Wakeup Storm)。
3. **磁碟空間與儲存拓撲分析 (Disk Space & Storage Topology Analysis)**：實體磁碟介面協定（NVMe / SATA / USB UAS vs BOT）、區塊對齊、掛載空間與 `dux` 空間回收分析、外接媒體 F3 容量驗證。
4. **磁碟 I/O 基準測試與調校 (Disk I/O Benchmark & Tuning)**：循序讀寫吞吐、4K 隨機/同步 IOPS 與延遲、Linux `/sys/block` 佇列與 `vm.dirty_*` 調校、macOS APFS I/O 觀測（完整知識庫與指令見 [references/disk.md](references/disk.md)）。

---

## Workflow

### 1. 全機硬體與系統快照 (System & Hardware Snapshot)

優先使用本 repo 跨平台（macOS / Ubuntu）探測腳本取得結構化基線：

```bash
# 一次執行全系統硬體與 OS 綜覽報告
pnpm run run:system:show
# 或直接執行
./scripts/system/show.sh
```

若只需針對單一子系統探測：

| 評估項目 | Repo 指令 | 底層腳本 |
| --- | --- | --- |
| 作業系統與核心 | `pnpm run run:system:os` | `./scripts/system/os.sh` |
| 處理器規格与核心數 | `pnpm run run:system:cpu` | `./scripts/system/cpu.sh` |
| 記憶體與 Swap 用量 | `pnpm run run:system:memory` | `./scripts/system/memory.sh` |
| 顯示卡 / GPU | `pnpm run run:system:gpu` | `./scripts/system/gpu.sh` |
| 磁碟掛載與分割區清單 | `pnpm run run:system:disk` | `./scripts/system/disk.sh` |
| USB 匯流排與外接裝置 | `pnpm run run:system:usb` | `./scripts/system/usb.sh` |
| 螢幕與解析度 | `pnpm run run:system:display` | `./scripts/system/display.sh` |
| 網路介面與 IP 狀態 | `pnpm run run:system:network` | `./scripts/system/network.sh` |
| 輸入裝置 | `pnpm run run:system:input` | `./scripts/system/input.sh` |
| 音訊裝置 | `pnpm run run:system:audio` | `./scripts/system/audio.sh` |

---

### 2. 運算、記憶體與耗電評估 (Compute, Memory & Energy Evaluation)

#### 2.1 CPU 與記憶體壓力 (macOS vs Ubuntu)

| 檢查面向 | macOS 指令 | Ubuntu / Linux 指令 | 判讀重點 |
| --- | --- | --- | --- |
| 負載與行程排行 | `top -l 2 -n 15 -o cpu` | `top -b -n 1 \| head -n 25` | `Load Avg` 是否長期超過邏輯核心數；有無單一行程卡滿核心 |
| 記憶體壓力與 Swap | `memory_pressure`、`vm_stat`、`sysctl vm.swapusage` | `free -h`、`vmstat 1 5` | macOS 看 `System-wide memory free percentage` 與 `Swapins/Swapouts`；Linux 看 `available` 與 `si`/`so`（每秒 swap in/out） |
| 系統阻塞壓力 (PSI) | N/A（看 `vm_stat` / `iostat`） | `cat /proc/pressure/{cpu,memory,io}` | `full avg10` > 10% 代表行程因資源不足顯著停頓 |

#### 2.2 macOS 耗電與喚醒風暴分析 (Wakeup Storm Analysis)

在 macOS 上，高 Context Switch 但低 CPU 佔用的背景行程會阻止晶片進入低功耗閒置狀態：

```bash
# 預設取樣 5 秒，列出前 15 名耗電與喚醒異常行程（免 sudo）
pnpm run run:system:energy

# 依 context switches 排序並拉長取樣至 10 秒
./scripts/system/energy.sh --interval 10 --sort csw

# 針對特定異常 PID 深入分析執行緒、socket、監看目錄與子行程
./scripts/system/energy.sh --pid <PID>

# 追加 powermetrics coalition 深度分析（需 sudo）
./scripts/system/energy.sh --deep
```

---

### 3. 磁碟空間與儲存裝置分析 (Disk Analysis)

> 深入的儲存協定、區塊對齊、核心佇列調校與基準測試細節，請先閱讀 [references/disk.md](references/disk.md)。

#### Step 1：儲存拓撲、傳輸介面與區塊屬性探測

```bash
# 探測實體磁碟 DEV, TRAN (nvme/sata/usb), MODEL, SIZE, MOUNTS 與對齊/快取資訊
pnpm run run:io:probe
# 或直接執行
./scripts/io/probe.sh
```

- **Ubuntu 補充檢查**：`lsusb -t`（確認 USB 外接碟為 `Driver=uas` 而非慢速 `usb-storage` BOT）、`/sys/block/<dev>/queue/{scheduler,read_ahead_kb,rotational,optimal_io_size}`。
- **macOS 補充檢查**：`diskutil info <dev>`、`system_profiler SPNVMeDataType SPUSBDataType`。

#### Step 2：磁碟空間用量與可清理候選分析

1. **檢視分割區剩餘空間與 Inode**：
   ```bash
   pnpm run run:system:disk
   df -i   # 排查空間未滿卻報 No space left on device
   ```
2. **掃描並列出 Top-N 空間佔用與可回收項目**：
   ```bash
   dux scan --min-size 50MB
   dux analyze --top 20
   ```
   *(若使用者需要互動式安全清理空間，請銜接 `disk-analyze` 技能之 Cleanup Wizard 流程)*
3. **指定目錄快速下鑽**：
   ```bash
   du -xhd 1 <target_dir> | sort -hr | head -n 20
   ```

#### Step 3：外接磁碟容量真偽與壞軌驗證（選用，具寫入操作）

```bash
pnpm run run:system:disk-verify -- /Volumes/<USB_DRIVE>
```

---

### 4. 磁碟 I/O 基準測試與調校 (Disk I/O Benchmark & Tuning)

#### Step 1：執行 Repo 內建 I/O 基準測試 (`bench.sh`)

量測目標目錄所在磁碟的 **Sequential Write**、**4K Sync Write (IOPS & Latency)**、**Sequential Read** 與 **4K Random Read (IOPS & Latency)**：

```bash
# 對預設 /tmp 執行基準測試（64 MiB 循序、50 次 4K 操作）
pnpm run run:io:bench

# 對指定掛載點進行更大樣本評測（例如 256 MiB 循序、200 次 4K 操作）
./scripts/io/bench.sh -d <target_mount_dir> -s 256 -o 200

# 一次執行裝置探測 + I/O 評測
./scripts/io/probe.sh --bench -d <target_mount_dir> -s 256 -o 200
```

#### Step 2：進階壓力測試與即時監測

- 當需要測試多佇列（Multi-queue `QD=8~32`）、長時間持續寫入（檢驗 SLC Cache 耗盡與過熱降速）或 p99 延遲時，依據 [references/disk.md](references/disk.md) 第 3 節執行 `fio` 與 `iostat`：
    - **Ubuntu 即時觀察**：`iostat -xz <dev> 1`、`sudo iotop -oP`
    - **macOS 即時觀察**：`iostat -d -w 1`、`sudo fs_usage -w -f diskio`

#### Step 3：針對瓶頸進行 I/O 調校

依據 [references/disk.md](references/disk.md) 第 4～6 節對症調整：
- **USB 外接 SSD 吞吐低落或卡頓**：檢查 `lsusb -t` 是否落入 `usb-storage` (BOT)、檢查 `/sys/block/<dev>/queue/rotational` 是否誤判為 `1`、調大循序場景之 `read_ahead_kb`。
- **大記憶體 Linux 主機寫入外接/慢速碟時系統凍結**：將 `sysctl` 之 `vm.dirty_background_bytes`（如 `16777216`）與 `vm.dirty_bytes`（如 `67108864`）改為絕對位元組上限，取代百分比 `*_ratio`。
- **高併發 IOPS 裝置 CPU 排程開銷高**：將 NVMe / 高速 SSD / UAS 的 `/sys/block/<dev>/queue/scheduler` 設為 `none`，掛載加上 `noatime`，並以定時 `fstrim` 取代同步 `discard`。
