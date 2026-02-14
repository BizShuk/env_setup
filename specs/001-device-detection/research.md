# Technical Research: 硬體檢測方法 (Hardware Detection Methods)

### macOS (Darwin)

在 macOS 上，最權威的工具是 `system_profiler`。

- **CPU**: `sysctl -n machdep.cpu.brand_string`, `sysctl -n hw.ncpu`
- **RAM**: `sysctl -n hw.memsize` (bytes), `system_profiler SPHardwareDataType`
- **Graphic Card**: `system_profiler SPDisplaysDataType`
- **Disk**: `diskutil list physical`, `system_profiler SPStorageDataType`
- **CD/DVD**: `system_profiler SPDiscBurningDataType`
- **USB**: `system_profiler SPUSBDataType`
- **Monitor**: `system_profiler SPDisplaysDataType`
- **Network**: `networksetup -listallhardwarereports`, `ifconfig`, `system_profiler SPNetworkDataType`
- **Keyboard/Mouse**: `system_profiler SPHidDataType` (通常包含在 USB/Bluetooth 裡)
- **Audio**: `system_profiler SPAudioDataType`

### Linux

Linux 系統取決於安裝的工具。

- **CPU**: `lscpu` 或 `cat /proc/cpuinfo`
- **RAM**: `free -h` 或 `cat /proc/meminfo`
- **Graphic Card**: `lspci | grep -i vga`
- **Disk**: `lsblk -d`, `fdisk -l`
- **CD/DVD**: `lsblk` (過濾 `rom`), `wodim --devices`
- **USB**: `lsusb`
- **Monitor**: `xrandr` (需要 GUI) 或 `ls /sys/class/drm/*/edid`
- **Network**: `ip addr`, `nmcli device status`
- **Keyboard/Mouse**: `cat /proc/bus/input/devices`
- **Audio**: `aplay -l` 或 `lspci | grep -i audio`

### 跨平台實現策略 (Cross-platform Strategy)

使用 `uname` 判斷作業系統類型：

- `Darwin`: 使用 `system_profiler` 和 `sysctl`。
- `Linux`: 使用 `lscpu`, `free`, `lspci`, `lsusb` 等常見命令（需檢查是否存在）。

### 格式化工具

- 使用 `printf` 進行對齊顯示。
- 使用顏色彩現代化輸出（ANSI colors）。
