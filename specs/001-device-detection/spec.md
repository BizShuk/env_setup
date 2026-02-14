# Feature Specification: 設備檢測腳本 (Device Detection Script)

**Feature Branch**: `001-device-detection`
**Created**: 2026-02-14
**Status**: Draft
**Input**: User description: "create a script to detect common device (cpu, ram, graphic card, cd/dvd/usb/monitor/network(wifi/lan)/keyboard/mouth/audio)"

### User Scenarios & Testing _(使用者情境與測試)_

#### User Story 1 - 快速查看硬體資訊 (Priority: P1)

作為一名系統管理員，我想要執行一個簡單的命令來查看伺服器或個人電腦的硬體配置，以便快速了解系統狀態。

**Why this priority**: 這是該工具的核心功能，使用者需要一個統一的介面來獲取多種硬體資訊。

**Acceptance Scenarios**:

1. **Given** 在 macOS 或 Linux 系統中，**When** 執行 `scan_devices`，**Then** 系統應顯示 CPU 型號、核心數、記憶體大小、硬碟大小、顯示卡、網路介面、USB 設備、顯示器、音訊設備等資訊。

---

### Requirements _(系統需求)_

#### Functional Requirements (功能需求)

- **FR-001**: 系統必須能夠檢測並顯示 CPU 資訊（型號、核心數、頻率）。
- **FR-002**: 系統必須能夠檢測並顯示 RAM 資訊（總量、已用量、槽位資訊）。
- **FR-003**: 系統必須能夠檢測並顯示顯示卡 (Graphic Card) 資訊。
- **FR-004**: 系統必須能夠檢測並顯示光碟機 (CD/DVD) 資訊（如果存在）。
- **FR-005**: 系統必須能夠檢測並顯示 USB 連接設備。
- **FR-006**: 系統必須能夠檢測並顯示顯示器 (Monitor) 資訊（解析度、連接方式）。
- **FR-007**: 系統必須能夠檢測並顯示網路介面 (WiFi/LAN) 狀態及 IP 位址。
- **FR-008**: 系統必須能夠檢測並顯示輸入設備（鍵盤、滑鼠）。
- **FR-009**: 系統必須能夠檢測並顯示音訊設備 (Audio Devices)。
- **FR-010**: 系統必須能夠檢測並顯示硬碟 (Disk) 與儲存空間資訊。
- **FR-011**: 腳本應支援 macOS 系統（主要目標）。
- **FR-012**: 腳本應具備基本的 Linux 支援（可選，但建議）。
- **FR-013**: 腳本必須將輸出同時顯示在螢幕上並寫入 `README.devices.md` 檔案中。
- **FR-014**: 檔案輸出必須符合 Markdown 格式（使用標題與反引號 ` ` 包裹 Key）。
- **FR-015**: 當同一類別下有多個設備或具有層級關係（如 USB Hub 與其下屬設備）時，必須使用縮排子列表（subtree）呈現。

### Success Criteria _(成功準則)_

- **SC-001**: 使用者執行腳本後，能在終端機看到所有列出的硬體類別。
- **SC-002**: 對於不存在的設備（如現代筆電可能沒有 CD/DVD），應友好地顯示 "Not Found" 或跳過。

### Assumptions _(假設)_

- 使用者具有執行相關系統命令（如 `system_profiler`, `lshw`, `lspci`）的權限。
- 主要運行環境為 macOS。
