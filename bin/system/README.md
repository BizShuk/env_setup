# 安全性稽核與工具 (Security Audits & Tools)

本目錄包含針對 macOS 系統進行安全性稽核、網路掃描與磁碟分析的腳本、設定檔與產出的稽核報告。

## 稽核工具概述 (Overview of Audit Tools)

本目錄提供以下安全性稽核工具與腳本：

- `disk_analysis-mac.sh`：磁碟與檔案系統安全性分析腳本，用於檢查敏感目錄權限及敏感檔案。
- `launch_audit-mac.sh`：啟動項 `LaunchAgents` 與 `LaunchDaemons` 稽核腳本，檢查有無異常背景常駐程式。
- `login_audit-mac.sh`：登入項與使用者帳戶稽核腳本，檢查使用者帳戶強度與自動登入設定。
- `network_security_audit-mac.sh`：網路安全性稽核腳本，掃描本機開啟的通訊埠及服務狀態。
- `network_topology_scan-mac.sh`：網路拓撲掃描腳本，用於探測與分析局域網內的活躍主機與通訊埠。

---

## macOS 安全性建議 (macOS Security Recommendations)

本子區段基於 `security/network_security_audit-mac.sh` 稽核結果，列出需立即處理的高風險項目。執行下列指令需 `sudo` 管理員權限。

### 高風險項目 (High Risk Items)

#### ① 開啟防火牆 (Firewall) — `最重要 (Most Critical)`

兩道防火牆（`Application Firewall` 應用層防火牆 + `pf` 封包過濾器）目前完全關閉。如同家門沒鎖，同一個網路上的任何人都可嘗試連入你的電腦。

```bash
# 啟用 Application Firewall（應用層防火牆）
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# 啟用 Stealth Mode（隱身模式：對未經請求的探測不回應）
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on
```

| 元件 (Component) | 預設狀態 (Default State) | 建議狀態 (Recommended) |
| --- | --- | --- |
| Application Firewall | off | on |
| Stealth Mode | off | on |
| `pf` Packet Filter | off (未載入) | 依需求手動啟用 |

#### ② 關閉螢幕分享 (Screen Sharing / VNC Port 5900)

VNC 服務正在執行且對所有介面開放，區域網路上的任何人都可看到你的螢幕甚至操控電腦。

`系統設定 (System Settings)` → `一般 (General)` → `分享 (Sharing)` → 關閉 `螢幕分享 (Screen Sharing)`

> GUI 步驟：
>
> 1. 開啟「系統設定」
> 2. 進入「一般」→「分享」
> 3. 關閉「螢幕分享」開關

#### ③ 關閉 SSH (Remote Login Port 22)

SSH 服務目前為開啟狀態。若無遠端登入 Mac 的需求，建議關閉以縮小攻擊面。

```bash
# 關閉 Remote Login (SSH)
sudo systemsetup -setremotelogin off
```

### 對照表 (Reference Table)

| 建議項 (Recommendation) | 影響服務 (Service) | 預設通訊埠 (Port) | 指令/路徑 (Command / Path) |
| --- | --- | --- | --- |
| 啟用防火牆 | Application Firewall | — | `socketfilterfw --setglobalstate on` |
| 啟用隱身模式 | Application Firewall | — | `socketfilterfw --setstealthmode on` |
| 關閉螢幕分享 | VNC | `5900` | 系統設定 → 分享 → 螢幕分享 |
| 關閉 SSH | Remote Login | `22` | `sudo systemsetup -setremotelogin off` |

### 驗證方式 (Verification)

執行後可重新跑一次稽核腳本，確認風險項目已消除：

```bash
./security/network_security_audit-mac.sh
```

並比對 `security/audit_results.txt` 中對應項目的狀態是否由 `OPEN` 變為 `CLOSED` / `OFF`。

### 備註 (Notes)

- 啟用 Application Firewall 不會阻斷已建立的外出連線，僅攔截未經授權的傳入連線
- Stealth Mode 會讓你的 Mac 對外不廣播存在性（不回應 ping、未請求的 TCP 探測）
- 關閉 SSH 會同時中斷 `ssh user@host` 的登入能力，請先確認無自動化或遠端操作需求
