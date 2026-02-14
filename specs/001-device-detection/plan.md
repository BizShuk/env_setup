# Implementation Plan: 設備檢測腳本 (Device Detection Script)

**Branch**: `001-device-detection` | **Date**: 2026-02-14 | **Spec**: [spec.md]

### Summary

實作一個名為 `scan_devices` 的 Bash 腳本，封裝系統底層命令以獲取硬體資訊。腳本將具有跨平台支援（macOS/Linux），並以格式良好的表格或條目形式輸出結果。

### Technical Context

**Language/Version**: Bash
**Primary Dependencies**:

- macOS: `system_profiler`, `sysctl`, `networksetup`
- Linux: `lscpu`, `lsusb`, `lspci`, `free`
  **Testing**: 手動執行腳本並驗證輸出的正確性。
  **Target Platform**: macOS (Darwin), Linux

### Constitution Check

- [x] **Library-First**: 否（此為獨立工具腳本）
- [x] **CLI Interface**: 是，純命令列工具
- [x] **Test-First**: 否（硬體相關，傾向於實際測試環境）
- [x] **Observability**: 否
- [x] **Simplicity**: 是，最小依賴

### Project Structure

```text
bin/
└── scan_devices    # 主腳本
```

### 實作步驟 (Steps)

1. **環境偵測**: 檢查 `uname` 以判定 OS。
2. **模組化偵測函數**:
   - `detect_cpu`
   - `detect_ram`
   - `detect_gpu`
   - `detect_disk`
   - `detect_storage` (CD/DVD/USB)
   - `detect_display` (Monitor)
   - `detect_network`
   - `detect_input` (Keyboard/Mouse)
   - `detect_input` (Keyboard/Mouse)
   - `detect_audio`
3. **格式化輸出**: 使用顏色區分標題與數據。
4. **檔案輸出**: 使用 `tee` 將結果寫入 `README.devices.md`。腳本將偵測到的資訊轉換為 Markdown 語法（例如使用 `##` 標題和 `- \`Key\`: Value`）。
5. **層級呈現 (Subtree)**: 針對多個設備與 USB Hub，實作縮排邏輯，將詳細資訊或下屬設備作為子列表項呈現。
6. **權限處理**: 某些 Linux 命令可能需要 `sudo` (例如 `lshw`)，腳本應在此類情況提示或降級使用其他命令。
