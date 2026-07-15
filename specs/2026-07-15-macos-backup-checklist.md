# macOS 設定完整備份與還原清單 (macOS Backup & Restore Checklist)

> 本檔把 System Settings 各分頁的可移植設定一對一對應到 `defaults` 鍵，逐一勾選、逐項還原。
> macOS 13+ (Ventura/Sonoma/Sequoia) 為 **System Settings**；macOS 12 及更早為 **System Preferences**。
> 對應備份工具將依本檔規格撰寫，放至 `bin/mac/` 內。

## 使用方式 (Usage)

1. 在源機 (source Mac) 對照本檔勾選要備份的項目。
2. 執行對應 dump 腳本，全部輸出落入 `~/projects/env_setup/dump/`。
3. 把 `dump/` 隨專案 commit / rsync 到目的機。
4. 在目的機 (target Mac) 執行對應 restore 腳本，必要者登出重啟生效。

每項格式：UI 路徑 → defaults 鍵 → 備份指令 → 還原指令。`☐` 為勾選框。

---

## 一、Apple ID (頂端圖示)

開啟：System Settings 點左上 `Apple ID 名稱`。

| ☐   | 項目                        | defaults 鍵                                    | 備份指令                                         | 還原指令                                                     |
| --- | --------------------------- | ---------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------ |
| ☐   | Sign-in Email               | 無 (Apple ID 帳號綁定)                         | —                                                | —                                                            |
| ☐   | iCloud Drive 同步選項       | 無 (逐 app 控)                                 | —                                                | —                                                            |
| ☐   | Private Relay               | 無                                             | —                                                | —                                                            |
| ☐   | Handoff / Camera Continuity | `NSGlobalDomain NSUserActivityTrackingEnabled` | `defaults read -g NSUserActivityTrackingEnabled` | `defaults write -g NSUserActivityTrackingEnabled -bool true` |

> ⚠️ Apple ID、iCloud Keychain、Messages in iCloud、Find My、Touch ID 指紋等均無法移植，必須在新機重登 + 重驗。

---

## 二、Wi-Fi / Network / Bluetooth

開啟：System Settings 左側列 → `Wi-Fi` / `Network` / `Bluetooth`。

| ☐   | 項目                          | defaults 鍵                                      | 備份指令                                                       | 還原指令                                                                    |
| --- | ----------------------------- | ------------------------------------------------ | -------------------------------------------------------------- | --------------------------------------------------------------------------- |
| ☐   | Wi-Fi 自動加入熱門連線        | 已記錄於 `com.apple.wifi.knownNetworks`          | `defaults read com.apple.wifi.knownNetworks`                   | ✗ (keychain 綁)                                                             |
| ☐   | Network location              | `SCDynamicStoreCopyDHCPParameters` 不可 export   | —                                                              | ✗                                                                           |
| ☐   | AirDrop 接收設定              | `com.apple.NetworkBrowser DisableAirDropSharing` | `defaults read com.apple.NetworkBrowser DisableAirDropSharing` | `defaults write com.apple.NetworkBrowser DisableAirDropSharing -bool false` |
| ☐   | Bluetooth 自動開啟            | `NSGlobalDomain BluetoothAutoSeekHIDDevices`     | `defaults read -g BluetoothAutoSeekHIDDevices`                 | `defaults write -g BluetoothAutoSeekHIDDevices -bool true`                  |
| ☐   | Bluetooth Advanced (HID 連線) | `com.apple.Bluetooth ControllerPowerState`       | `defaults read com.apple.Bluetooth`                            | `defaults write com.apple.Bluetooth ControllerPowerState -int 1`            |

> ⚠️ 已儲存的 Wi-Fi 密碼在 keychain，必須重新輸入或從舊機匯出 keychain。

---

## 三、Notifications

開啟：System Settings 左列 → `Notifications`。

| ☐   | 項目                              | defaults 鍵                                      | 備份指令                                 | 還原指令                                                        |
| --- | --------------------------------- | ------------------------------------------------ | ---------------------------------------- | --------------------------------------------------------------- |
| ☐   | 預設風格 (banner/alert)           | `com.apple.ncui`                                 | `defaults read com.apple.ncui`           | `defaults write com.apple.ncui`                                 |
| ☐   | Do Not Disturb 排程               | `com.apple.doitnotdisturb.plist`                 | `defaults read com.apple.doitnotdisturb` | `defaults write com.apple.doitnotdisturb dndEnabled -bool true` |
| ☐   | Focus 模式配置 (Work/Personal...) | `com.apple.focus.plist` (`<focus-id>.focusmode`) | `defaults read com.apple.focus`          | `defaults import com.apple.focus focus.plist`                   |
| ☐   | 個別 App 通知權限                 | 各 app `<bundle-id>` plist + TCC.db              | 需 `database_files/TCC.db` 匯出          | 需寫回 TCC.db                                                   |

---

## 四、Sound

開啟：System Settings → `Sound`。

| ☐   | 項目                | defaults 鍵                     | 備份指令                                      | 還原指令                                                            |
| --- | ------------------- | ------------------------------- | --------------------------------------------- | ------------------------------------------------------------------- |
| ☐   | 預設播放裝置        | `com.apple.audio.AudioDevice`   | `defaults read com.apple.audio.AudioDevice`   | `defaults import com.apple.audio.AudioDevice sound.plist`           |
| ☐   | 輸入音量 / 輸出音量 | `com.apple.audio.system`        | `defaults read -g NSFixedInputVolume*`        | ✗ (聲音裝置綁硬體)                                                  |
| ☐   | 開機音效            | `com.apple.PowerChime`          | `defaults read com.apple.PowerChime`          | `defaults write com.apple.PowerChime ChimeOnAllHardware -bool true` |
| ☐   | 警示音              | `com.apple.sound.beep.feedback` | `defaults read com.apple.sound.beep.feedback` | `defaults write com.apple.sound.beep.feedback -bool true`           |

---

## 五、Focus

開啟：System Settings → `Focus`。

| ☐   | 項目                         | defaults 鍵                           | 備份指令                                    | 還原指令                                                                             |
| --- | ---------------------------- | ------------------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------ |
| ☐   | Focus 模式啟用狀態           | `com.apple.focus.focusMode-1`         | `defaults read com.apple.focus`             | `defaults import com.apple.focus focus.plist`                                        |
| ☐   | Allowed Apps                 | 內嵌於 `com.apple.focus`              | 同上                                        | 同上                                                                                 |
| ☐   | Do Not Disturb While Driving | `com.apple.assistant.support` 部份    | `defaults read com.apple.assistant.support` | `defaults write com.apple.assistant.support "Time to read new messages" -bool false` |
| ☐   | Share across devices         | `NSGlobalDomain NSFocusStatusEnabled` | `defaults read -g NSFocusStatusEnabled`     | `defaults write -g NSFocusStatusEnabled -bool false`                                 |

---

## 六、Screen Time

開啟：System Settings → `Screen Time`。

| ☐   | 項目                  | defaults 鍵              | 備份指令                               | 還原指令                                                  |
| --- | --------------------- | ------------------------ | -------------------------------------- | --------------------------------------------------------- |
| ☐   | 每日用量上限          | `com.apple.screenfamily` | `defaults read com.apple.screenfamily` | `defaults import com.apple.screenfamily screentime.plist` |
| ☐   | Downtime / App Limits | 同上                     | 同上                                   | 同上                                                      |
| ☐   | Content & Privacy     | iCloud Family 綁         | ✗                                      | ✗                                                         |

> ⚠️ Screen Time 全 Family Sharing 同步，主要在雲端。

---

## 七、General

開啟：System Settings 左列 → `General`，展開後有 7 個子分頁。

### 七 A. General > About

| ☐   | 項目          | defaults 鍵                                              | 備份指令                                       |
| --- | ------------- | -------------------------------------------------------- | ---------------------------------------------- |
| ☐   | Computer name | `NSGlobalDomain HostName / LocalHostName / ComputerName` | `scutil --get ComputerName` 等三項 export 文字 |

### 七 B. General > Software Update

| ☐   | 項目           | defaults 鍵                                                  | 備份指令                                 | 還原指令                                                                            |
| --- | -------------- | ------------------------------------------------------------ | ---------------------------------------- | ----------------------------------------------------------------------------------- |
| ☐   | 自動更新 macOS | `com.apple.SoftwareUpdate AutomaticallyInstallAppUpdates` 等 | `defaults read com.apple.SoftwareUpdate` | `defaults write com.apple.SoftwareUpdate AutomaticallyInstallAppUpdates -bool true` |
| ☐   | 安裝系統資料檔 | `com.apple.SoftwareUpdate CriticalUpdateInstall`             | 同上                                     | 同上                                                                                |

### 七 C. General > Time Machine

| ☐   | 項目        | defaults 鍵                                                                    | 備份指令                      |
| --- | ----------- | ------------------------------------------------------------------------------ | ----------------------------- |
| ☐   | TM 排程頻率 | 無                                                                             | `tmutil destinationinfo` 純查 |
| ☐   | TM 排除清單 | `/Library/Preferences/com.apple.TimeMachine.plist` 的 `ExcludedVolumeUUIDList` | 讀取後過濾                    |

### 七 D. General > Login Items & Extensions

| ☐   | 項目                    | defaults 鍵                                                                   | 備份指令                                          | 還原指令                                        |
| --- | ----------------------- | ----------------------------------------------------------------------------- | ------------------------------------------------- | ----------------------------------------------- |
| ☐   | Login Items (App)       | 寫入 `~/Library/Application Support/com.apple.backgroundtaskmanagementagent/` | ❌ SQLite dump+insert                             | 重灌用 `osascript "tell app \"System Events\""` |
| ☐   | System Extensions       | `~/Library/Preferences/ByHost/com.apple.SystemManagement.*.plist`             | `defaults read ByHost/com.apple.SystemManagement` | `defaults import <file>`                        |
| ☐   | Launch Agents (user)    | `~/Library/LaunchAgents/*.plist`                                              | `ls -la` 後 tar 整包                              |
| ☐   | Launch Daemons (system) | `/Library/LaunchDaemons/*.plist`                                              | sudo tar                                          | sudo cp                                         |

### 七 E. General > Login Password

| ☐   | 項目                     | defaults 鍵                 |
| --- | ------------------------ | --------------------------- |
| ☐   | Password hint (系統提示) | 不可 export (系統登入 meta) |

### 七 F. General > Sharing

| ☐   | 項目                 | defaults 鍵                                             | 備份指令                                  | 還原指令                                               |
| --- | -------------------- | ------------------------------------------------------- | ----------------------------------------- | ------------------------------------------------------ |
| ☐   | Screen Sharing (VNC) | `com.apple.ScreenSharing`                               | `defaults read com.apple.ScreenSharing`   | `defaults import com.apple.ScreenSharing shared.plist` |
| ☐   | File Sharing         | `com.apple.AppleFileServer.guest` 等                    | `defaults read com.apple.AppleFileServer` | `defaults import com.apple.AppleFileServer afp.plist`  |
| ☐   | Remote Login (SSH)   | `com.apple.universalaccessd ssh`                        | `systemsetup -getremotelogin`             | `systemsetup -setremotelogin on`                       |
| ☐   | Remote Management    | `/Library/Preferences/com.apple.RemoteManagement.plist` | copy + sudo                               | sudo cp                                                |

### 七 G. General > Transfer or Reset

| ☐                   | 項目 | defaults 鍵 |
| ------------------- | ---- | ----------- |
| (僅清除 / 重灌用途) | —    | —           |

---

## 八、Appearance (macOS 12+ 在 Desktop & Dock 上方)

開啟：System Settings → `Appearance`。

| ☐   | 項目                   | defaults 鍵                                                                       | 備份指令                                                                 | 還原指令                                                    |
| --- | ---------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | ----------------------------------------------------------- |
| ☐   | Dark Mode              | `NSGlobalDomain AppleInterfaceStyle` / `AppleInterfaceStyleSwitchesAutomatically` | `defaults read -g AppleInterfaceStyle`                                   | `defaults write -g AppleInterfaceStyle Dark`                |
| ☐   | Highlight color        | `NSGlobalDomain AppleAccentColor` (int)                                           | `defaults read -g AppleAccentColor`                                      | `defaults write -g AppleAccentColor -int 6`                 |
| ☐   | Sidebar icon size      | `NSGlobalDomain NSTableViewDefaultSizeMode`                                       | `defaults read -g NSTableViewDefaultSizeMode`                            | `defaults write -g NSTableViewDefaultSizeMode -int 2`       |
| ☐   | Show scroll bars       | `NSGlobalDomain AppleShowScrollBars` (`Always` / `Automatic` / `WhenScrolling`)   | `defaults read -g AppleShowScrollBars`                                   | `defaults write -g AppleShowScrollBars Automatic`           |
| ☐   | Click in scroll bar to | `NSGlobalDomain AppleScrollerPagingBehavior`                                      | `defaults read -g AppleScrollerPagingBehavior`                           | `defaults write -g AppleScrollerPagingBehavior -bool false` |
| ☐   | Default web browser    | `com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers`             | `defaults read com.apple.LaunchServices/com.apple.launchservices.secure` | `defaults write ... LSHandlers -dict`                       |

---

## 九、Accessibility

開啟：System Settings → `Accessibility`，展開後有 12 個子分頁。

### 九 A. Accessibility > Display

| ☐   | 項目                        | defaults 鍵                                              | 備份指令                                                     | 還原指令                                                                 |
| --- | --------------------------- | -------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------ |
| ☐   | Increase contrast           | `AppleAccessibilityEnhancedContrastEnabled`              | `defaults read -g AppleAccessibilityEnhancedContrastEnabled` | `defaults write -g ... -bool true`                                       |
| ☐   | Reduce transparency         | `com.apple.universalaccess reduceTransparency`           | `defaults read com.apple.universalaccess reduceTransparency` | `defaults write com.apple.universalaccess reduceTransparency -bool true` |
| ☐   | Differentiate without color | `AppleDisplayColorblindMode`                             | `defaults read -g AppleDisplayColorblindMode`                | `defaults write -g AppleDisplayColorblindMode -bool true`                |
| ☐   | Reduce motion               | `com.apple.universalaccess reduceMotion`                 | `defaults read com.apple.universalaccess reduceMotion`       | `defaults write com.apple.universalaccess reduceMotion -bool true`       |
| ☐   | Color filters               | `com.apple.mediaaccessibility AVColorFitlerType`         | `defaults read com.apple.mediaaccessibility`                 | ✗                                                                        |
| ☐   | Text size                   | `com.apple.UIKit UIAppFonts` / `AppleTextSizeMultiplier` | `defaults read -g AppleTextSizeMultiplier`                   | ✗ (重啟才生效)                                                           |

### 九 B. Accessibility > Zoom

| ☐   | 項目                             | defaults 鍵                           | 備份指令                                  |
| --- | -------------------------------- | ------------------------------------- | ----------------------------------------- |
| ☐   | Use keyboard shortcuts / gesture | `com.apple.universalaccess zoomStyle` | `defaults read com.apple.universalaccess` |

### 九 C. Accessibility > Live Captions / Spoken Content / Voice Control / Captions

> 每項為專屬網域 (例如 `com.apple.speech.recognition.prefs`)。

### 九 D. Accessibility > Pointer Control

| ☐   | 項目                     | defaults 鍵                                | 備份指令                                                 |
| --- | ------------------------ | ------------------------------------------ | -------------------------------------------------------- |
| ☐   | Shape and size of cursor | `com.apple.universalaccess cursorSize`     | `defaults read com.apple.universalaccess cursorSize`     |
| ☐   | Dwell time               | `com.apple.universalaccess dwellClickTime` | `defaults read com.apple.universalaccess dwellClickTime` |

---

## 十、Control Center

開啟：System Settings → `Control Center`。

| ☐   | 項目                                                                                                     | defaults 鍵                                     | 備份指令                                                      | 還原指令                                           |
| --- | -------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | ------------------------------------------------------------- | -------------------------------------------------- |
| ☐   | 控制中心項目 (Bluetooth / Display / Wi-Fi)                                                               | `com.apple.controlcenter` 全域 plist            | `defaults read com.apple.controlcenter`                       | `defaults import ...`                              |
| ☐   | Always show in menu bar                                                                                  | per-module bool                                 | 同上                                                          | 同上                                               |
| ☐   | Battery percentage in menubar                                                                            | `com.apple.controlcenter ShowBatteryPercentage` | `defaults read com.apple.controlcenter ShowBatteryPercentage` | `defaults write -bool true`                        |
| ☐   | Menu Bar Only (Wi-Fi / Bluetooth / Clock / Airdrop / Focus / Stage Manager / Screen Mirroring / Display) | 各 module 內 `MenubarBehavior`                  | 同上                                                          | 同上                                               |
| ☐   | Battery: Low Power Mode auto-trigger                                                                     | `com.apple.batterymode`                         | `defaults read com.apple.batterymode`                         | `defaults write com.apple.batterymode -bool false` |

---

## 十一、Siri & Spotlight

開啟：System Settings → `Siri & Spotlight`。

| ☐   | 項目                                 | defaults 鍵                                            | 備份指令                                         | 還原指令                                                     |
| --- | ------------------------------------ | ------------------------------------------------------ | ------------------------------------------------ | ------------------------------------------------------------ |
| ☐   | Ask Siri 啟用                        | `com.apple.Siri StatusMenuVisible`                     | `defaults read com.apple.Siri StatusMenuVisible` | `defaults write com.apple.Siri StatusMenuVisible -bool true` |
| ☐   | Keyboard shortcut for Siri           | `com.apple.Siri AppleIntelligence.*`                   | `defaults read com.apple.Siri`                   | ✗ (與 Symbolichotkeys 衝突)                                  |
| ☐   | Language / Voice                     | `com.apple.speech.recognition.SpeechRecognitionLocale` | `defaults read com.apple.speech.recognition`     | `defaults write`                                             |
| ☐   | Spotlight Search Results             | `com.apple.Spotlight SearchList` (per-category bool)   | `defaults read com.apple.Spotlight SearchList`   | `defaults write -array ...`                                  |
| ☐   | Spotlight Privacy 排除               | `com.apple.Spotlight ServerContextDisabledPaths`       | `defaults read com.apple.Spotlight`              | 手動加回                                                     |
| ☐   | Apple Intelligence & Siri Suggestion | `com.apple.Siri AppleIntelligence Enabled`             | `defaults read com.apple.Siri`                   | `defaults write ... -bool false`                             |

---

## 十二、Privacy & Security

開啟：System Settings → `Privacy & Security`。

| ☐   | 項目                                                       | defaults 鍵                                                   | 備份指令                                     | 還原指令                     |
| --- | ---------------------------------------------------------- | ------------------------------------------------------------- | -------------------------------------------- | ---------------------------- |
| ☐   | Location Services (整體)                                   | `com.apple.locationd`                                         | `defaults read com.apple.locationd`          | ✗ (TCC 控)                   |
| ☐   | 各 App Location 授權                                       | `~/Library/Application Support/com.apple.TCC/TCC.db` (SQLite) | `sqlite3 TCC.db "select * from access"` 純查 | 必須重灌 OS 後重授權         |
| ☐   | Contacts / Calendars / Photos / Accessibility / Files 權限 | TCC.db                                                        | 需 `sqlite3` dump                            | 需 sqlite insert             |
| ☐   | Analytics 自動傳送                                         | `com.apple.AppleFileConduit*` 等                              | `defaults read com.apple.AppleFileConduit`   | `defaults write -bool false` |
| ☐   | Improve Siri / Support                                     | `com.apple.Siri` 多項 keys                                    | `defaults read com.apple.Siri`               | `defaults write`             |
| ☐   | Firewall 允許清單                                          | `/Library/Preferences/com.apple.alf.plist`                    | sudo cp                                      | sudo cp                      |
| ☐   | 已允許的 App (App Management)                              | `com.apple.security.firewall`                                 | sudo cat                                     | sudo apply                   |
| ☐   | Screen Recording / Accessibility 自動化                    | 登入後需手動在 Privacy & Security 授權                        | —                                            | ✗                            |
| ☐   | FileVault                                                  | `fdesetup` (CLI)                                              | `fdesetup status`                            | ✗ (硬體綁)                   |
| ☐   | Allow apps from App Store / Identified developers          | 無 (Gatekeeper 全機)                                          | —                                            | —                            |

> ⚠️ TCC.db 紀錄每個 app 對每個資源的授權，跨機不可直接複製；必須在新機重灌 OS 後從頭授權。Workaround: `sqlite3 TCC.db ".dump"` 取得 SQL，再手工 select 適合的 grants，但 Apple 強烈反對。

---

## 十三、Desktop & Dock

開啟：System Settings → `Desktop & Dock`。

### 十三 A. Dock Size & Magnification

| ☐   | 項目          | defaults 鍵                            | 備份指令                                     | 還原指令                                                 |
| --- | ------------- | -------------------------------------- | -------------------------------------------- | -------------------------------------------------------- |
| ☐   | Size          | `com.apple.dock tilesize` (int 16~128) | `defaults read com.apple.dock tilesize`      | `defaults write com.apple.dock tilesize -int 48`         |
| ☐   | Magnification | `com.apple.dock magnification`         | `defaults read com.apple.dock magnification` | `defaults write com.apple.dock magnification -bool true` |

### 十三 B. Dock 位置與動畫

| ☐   | 項目                                       | defaults 鍵                              | 備份指令                                               | 還原指令                                                            |
| --- | ------------------------------------------ | ---------------------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------- |
| ☐   | Position on screen (Bottom / Left / Right) | `com.apple.dock orientation`             | `defaults read com.apple.dock orientation`             | `defaults write com.apple.dock orientation bottom`                  |
| ☐   | Minimized window animation (Genie / Scale) | `com.apple.dock mineffect`               | `defaults read com.apple.dock mineffect`               | `defaults write com.apple.dock mineffect genie`                     |
| ☐   | Double-click window title bar action       | `-g AppleActionOnDoubleClick`            | `defaults read -g AppleActionOnDoubleClick`            | `defaults write -g AppleActionOnDoubleClick Fill`                   |
| ☐   | Minimize windows into application icon     | `com.apple.dock minimize-to-application` | `defaults read com.apple.dock minimize-to-application` | `defaults write com.apple.dock minimize-to-application -bool false` |
| ☐   | Animate opening applications               | `com.apple.dock launchanim`              | `defaults read com.apple.dock launchanim`              | `defaults write com.apple.dock launchanim -bool true`               |
| ☐   | Automatically hide and show the Dock       | `com.apple.dock autohide`                | `defaults read com.apple.dock autohide`                | `defaults write com.apple.dock autohide -bool true`                 |
| ☐   | Show indicators for open applications      | `com.apple.dock show-process-indicators` | `defaults read com.apple.dock show-process-indicators` | `defaults write com.apple.dock show-process-indicators -bool true`  |
| ☐   | Show suggested and recent apps in Dock     | `com.apple.dock show-recents`            | `defaults read com.apple.dock show-recents`            | `defaults write com.apple.dock show-recents -bool false`            |

### 十三 C. Dock 排列 (App 與資料夾)

| ☐   | 項目                      | 機制                                              | 工具                                |
| --- | ------------------------- | ------------------------------------------------- | ----------------------------------- |
| ☐   | Apps in Dock (左半)       | `com.apple.dock.plist` 內 `persistent-apps` array | `dockutil --add ... --position ...` |
| ☐   | Stacks / Folders (右半)   | `persistent-others` array                         | `dockutil --add ... --type folder`  |
| ☐   | 最近使用的 App (顯示與否) | `show-recents` + `recent-apps`                    | 上一組 `show-recents` 已列          |

### 十三 D. Desktop & Stage Manager

| ☐   | 項目                              | defaults 鍵                                              | 備份指令                                | 還原指令          |
| --- | --------------------------------- | -------------------------------------------------------- | --------------------------------------- | ----------------- |
| ☐   | Stage Manager                     | `com.apple.WindowManager`                                | `defaults read com.apple.WindowManager` | `defaults import` |
| ☐   | Show windows from same app        | `StageManagerHideWidgets` 等                             | 同上                                    | 同上              |
| ☐   | Click wallpaper to reveal Desktop | `com.apple.WindowManager EnableDetachableWindowGrouping` | 同上                                    | 同上              |

### 十三 E. Window & Menu Bar

| ☐   | 項目                                 | defaults 鍵                                                                  | 備份指令                                                      | 還原指令                                          |
| --- | ------------------------------------ | ---------------------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------- |
| ☐   | Prefer tabs when opening documents   | `NSGlobalDomain AppleWindowTabbingMode` (`always` / `fullscreen` / `manual`) | `defaults read -g AppleWindowTabbingMode`                     | `defaults write -g AppleWindowTabbingMode manual` |
| ☐   | Show in menu bar (Bluetooth / Clock) | 各 module 在 `com.apple.controlcenter`                                       | 同上                                                          | 同上                                              |
| ☐   | Battery percentage in menubar        | `com.apple.controlcenter ShowBatteryPercentage`                              | `defaults read com.apple.controlcenter ShowBatteryPercentage` | `defaults write -bool true`                       |
| ☐   | Clock Options (Date / Weekday / Sec) | `com.apple.menuextra.clock DateFormat` 等                                    | `defaults read com.apple.menuextra.clock`                     | `defaults write`                                  |
| ☐   | Battery: Show percentage             | `com.apple.controlcenter.battery ShowBatteryPercentage`                      | 同上                                                          | 同上                                              |

---

## 十四、Screens

開啟：System Settings → `Screens` (舊為 `Display`)。

### 十四 A. 主螢幕

| ☐   | 項目                                            | 機制                                           | 指令                                                              |
| --- | ----------------------------------------------- | ---------------------------------------------- | ----------------------------------------------------------------- |
| ☐   | Resolution (Default / More space / Larger text) | `com.apple.windowserver` (`DisplayVendorID-*`) | `defaults read /Library/Preferences/com.apple.windowserver.plist` |
| ☐   | Brightness                                      | 無 (DDC)；可 iGPU 調整                         | `brightness 0.7` (需第三方)                                       |
| ☐   | True Tone                                       | `com.apple.preferences.displays`               | `defaults read com.apple.preferences.displays`                    |
| ☐   | Refresh rate                                    | `com.apple.windowserver` `Display*RefreshRate` | 同上                                                              |
| ☐   | Rotation                                        | 寫入 NVRAM                                     | `system_profiler SPDisplaysDataType`                              |
| ☐   | Color profile                                   | `/Library/ColorSync/Profiles/` (整包 copy)     | sudo rsync                                                        |

### 十四 B. Arrange (多螢幕排列)

| ☐   | 項目                   | 機制                                 | 還原                 |
| --- | ---------------------- | ------------------------------------ | -------------------- |
| ☐   | Arrangement (排列順序) | `com.apple.windowserver DisplaySets` | 建議重灌後直接拖出來 |

### 十四 C. Advanced

| ☐   | 項目                                             | defaults 鍵                        | 備份指令                                                          | 還原指令 |
| --- | ------------------------------------------------ | ---------------------------------- | ----------------------------------------------------------------- | -------- |
| ☐   | Scaled / HiDPI                                   | `com.apple.windowserver`           | `defaults read /Library/Preferences/com.apple.windowserver.plist` | sudo cp  |
| ☐   | Variable refresh rate / ProMotion                | `com.apple.windowserver ProMotion` | 同上                                                              | 同上     |
| ☐   | Universal Control / Sidecar / Stage Manager 投影 | 圖形化設定                         | 重灌重配                                                          | ✗        |

---

## 十五、Wallpaper

開啟：System Settings → `Wallpaper`。

| ☐   | 項目                           | 機制                                                           | 備份                                                                      | 還原             |
| --- | ------------------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------- | ---------------- |
| ☐   | Dynamic / Static / Photo       | `~/Library/Application Support/com.apple.wallpaper/` 整包 copy | `plutil -p ~/Library/Application Support/com.apple.wallpaper/store.plist` | copy             |
| ☐   | Multiple wallpaper per display | 同上                                                           | 同上                                                                      | 同上             |
| ☐   | Picture rotation / shuffle     | `com.apple.wallpaper changer` plist                            | `defaults read com.apple.wallpaper`                                       | `defaults write` |

---

## 十六、Battery

開啟：System Settings → `Battery`。

| ☐   | 項目                                             | defaults 鍵                                               | 備份指令                                        | 還原指令                                                                |
| --- | ------------------------------------------------ | --------------------------------------------------------- | ----------------------------------------------- | ----------------------------------------------------------------------- |
| ☐   | Battery Health (Maximum Capacity)                | `ioreg -l` 讀取                                           | system_profiler SPPowerDataType                 | ✗ (電池固有)                                                            |
| ☐   | Optimized Battery Charging                       | `batteryd` plist                                          | `defaults read com.apple.batteryd`              | `defaults write com.apple.batteryd OptimizedChargingEnabled -bool true` |
| ☐   | Low Power Mode                                   | `com.apple.batterymode` (`lowpowermode` + `spassthrough`) | `defaults read com.apple.batterymode`           | `defaults write com.apple.batterymode lowpowermode -bool true`          |
| ☐   | Schedule Start / Stop                            | `com.apple.batterycharger.schedule*`                      | `defaults read com.apple.batterycharger`        | `defaults write`                                                        |
| ☐   | Show percentage                                  | `com.apple.controlcenter.battery`                         | `defaults read com.apple.controlcenter.battery` | `defaults write -bool true`                                             |
| ☐   | Power Mode (High Performance / Auto / Low Power) | `com.apple.systempower` `powermode`                       | `defaults read com.apple.systempower`           | `defaults write com.apple.systempower powermode -int 0`                 |

---

## 十七、Lock Screen

開啟：System Settings → `Lock Screen`。

| ☐   | 項目                     | defaults 鍵                                  | 備份指令                                       | 還原指令                                                     |
| --- | ------------------------ | -------------------------------------------- | ---------------------------------------------- | ------------------------------------------------------------ |
| ☐   | Require password after X | `com.apple.screensaver idleTime` + 鎖定延遲  | `defaults read com.apple.screensaver`          | `defaults write com.apple.screensaver askForPassword -int 1` |
| ☐   | Show large clock         | `com.apple.screensaver largeClock`           | 同上                                           | 同上                                                         |
| ☐   | Message when locked      | `com.apple.ScreenSaverChooser HotCorners` 等 | 同上                                           | 同上                                                         |
| ☐   | Hot Corners (左上右下)   | `com.apple.dock wvous-*`                     | `defaults read com.apple.dock wvous-tl-corner` | `defaults write com.apple.dock wvous-tl-corner -int 0`       |
| ☐   | Lock screen wallpaper    | 與 Wallpaper 顯示協調                        | 同 Wallpaper                                   | 同 Wallpaper                                                 |

---

## 十八、Touch ID & Password

開啟：System Settings → `Touch ID & Password`。

| ☐   | 項目                                                                      | 機制                  | 備份 |
| --- | ------------------------------------------------------------------------- | --------------------- | ---- |
| ☐   | Touch ID 指紋 (左 / 右各 3)                                               | Secure Enclave 不可讀 | ✗    |
| ☐   | Use Touch ID for unlock / Apple Pay / iTunes / Safari AutoFill / Terminal | 各 app 偏好           | ✗    |
| ☐   | Apple Watch 解鎖                                                          | Apple ID 綁           | ✗    |

---

## 十九、Users & Groups

開啟：System Settings → `Users & Groups`。

| ☐   | 項目                                               | defaults 鍵                                        | 備份                                  | 還原             |
| --- | -------------------------------------------------- | -------------------------------------------------- | ------------------------------------- | ---------------- |
| ☐   | Account full name / username / icon                | `~/.account` + `dscl .`                            | `dscl . read /Users/<me>`             | ✗ (OS 帳戶)      |
| ☐   | Admin / Standard                                   | `dscl .` 查                                        | `dscl . read /Groups/admin`           | ✗                |
| ☐   | Login items (per user)                             | `~/Library/Preferences/com.apple.loginitems.plist` | `defaults read com.apple.loginitems`  | `defaults write` |
| ☐   | Guest user / Show windows from background services | `com.apple.loginwindow`                            | `defaults read com.apple.loginwindow` | `defaults write` |

---

## 二十、Internet Accounts

開啟：System Settings → `Internet Accounts`。

| ☐   | 項目                                      | 機制                                               | 備份                        |
| --- | ----------------------------------------- | -------------------------------------------------- | --------------------------- |
| ☐   | Google / iCloud / Microsoft / Yahoo / AOL | 各 app token 寫於 `~/Library/Accounts/` + keychain | 不可 import (OAuth refresh) |
| ☐   | CardDAV / CalDAV 來源                     | 每個 provision 在對應 app 內                       | ✗                           |
| ☐   | Mail accounts                             | Mail.app 自存                                      | ✗                           |

> ⚠️ 全部網路帳號必須在新機重新登入 + OAuth。

---

## 二十一、Keyboard

開啟：System Settings → `Keyboard`，展開 4 個子分頁。

### 二十一 A. Keyboard > Text

| ☐   | 項目                           | defaults 鍵                                                                            | 備份指令                                                     | 還原指令                                                    |
| --- | ------------------------------ | -------------------------------------------------------------------------------------- | ------------------------------------------------------------ | ----------------------------------------------------------- |
| ☐   | Key repeat rate                | `NSGlobalDomain KeyRepeat`                                                             | `defaults read -g KeyRepeat`                                 | `defaults write -g KeyRepeat -int 2`                        |
| ☐   | Delay Until Repeat             | `NSGlobalDomain InitialKeyRepeat`                                                      | `defaults read -g InitialKeyRepeat`                          | `defaults write -g InitialKeyRepeat -int 15`                |
| ☐   | fn / Globe key 行為            | `NSGlobalDomain AppleFunctionKeyMode`                                                  | `defaults read -g AppleFunctionKeyMode`                      | ✗                                                           |
| ☐   | Adjust keyboard brightness     | `/Library/Preferences/com.apple.keyboard.preferences`                                  | sudo cp                                                      | sudo cp                                                     |
| ☐   | Text Replacements (使用者字典) | `~/Library/Preferences/.GlobalPreferences.plist` 中 `NSUserDictionaryReplacementItems` | `defaults read -g NSUserDictionaryReplacementItems`          | `defaults write -g NSUserDictionaryReplacementItems -array` |
| ☐   | Spelling / Substitutions       | `NSGlobalDomain NSAutomatic*` 系列                                                     | `defaults read -g NSAutomaticCapitalizationEnabled`          | `defaults write`                                            |
| ☐   | Input Sources (輸入法)         | `~/Library/Preferences/com.apple.HIToolbox.plist` 的 `AppleEnabledInputSources`        | `defaults read com.apple.HIToolbox AppleEnabledInputSources` | `defaults import com.apple.HIToolBox.plist`                 |

### 二十一 B. Keyboard > Dictation

| ☐   | 項目                 | defaults 鍵                                             | 備份指令                                     | 還原指令                        |
| --- | -------------------- | ------------------------------------------------------- | -------------------------------------------- | ------------------------------- |
| ☐   | Dictation on / off   | `com.apple.speech.recognition DictationEnabled`         | `defaults read com.apple.speech.recognition` | `defaults write ... -bool true` |
| ☐   | Auto-punctuation     | `com.apple.speech.recognition DictationAutoPunctuation` | 同上                                         | 同上                            |
| ☐   | Continuous Dictation | `com.apple.speech.recognition DictationContinuous`      | 同上                                         | 同上                            |

### 二十一 C. Keyboard > Shortcuts (App Shortcuts)

> ✅ 完整支援，已由 `bin/mac/mac_keyboard_shortcuts_dump.sh` 處理。

### 二十一 D. Keyboard > Input Sources

| ☐   | 項目       | 機制                  | 還原                                  |
| --- | ---------- | --------------------- | ------------------------------------- |
| ☐   | 輸入法清單 | `com.apple.HIToolbox` | `defaults import com.apple.HIToolbox` |

---

## 二十二、Mouse

開啟：System Settings → `Mouse`。

| ☐   | 項目                                  | defaults 鍵                                     | 備份指令                                          | 還原指令                                             |
| --- | ------------------------------------- | ----------------------------------------------- | ------------------------------------------------- | ---------------------------------------------------- |
| ☐   | Tracking speed                        | `NSGlobalDomain com.apple.mouse.scaling`        | `defaults read -g com.apple.mouse.scaling`        | `defaults write -g com.apple.mouse.scaling -int 2.5` |
| ☐   | Natural scrolling                     | `NSGlobalDomain com.apple.swipescrolldirection` | `defaults read -g com.apple.swipescrolldirection` | `defaults write ... -bool true`                      |
| ☐   | Secondary click                       | `com.apple.mouse rightclick`                    | `defaults read com.apple.mouse rightclick`        | `defaults write ... -bool true`                      |
| ☐   | Smart zoom                            | `com.apple.mouse.scaling`                       | 同上                                              | 同上                                                 |
| ☐   | Mission Control / Swipe between pages | `com.apple.Mouse.plist`                         | `defaults read com.apple.Mouse`                   | `defaults write`                                     |

---

## 二十三、Trackpad

開啟：System Settings → `Trackpad`，3 個子分頁。

### 二十三 A. Trackpad > Point & Click

| ☐   | 項目                          | defaults 鍵                                                            | 備份指令                                          | 還原指令         |
| --- | ----------------------------- | ---------------------------------------------------------------------- | ------------------------------------------------- | ---------------- |
| ☐   | Tracking speed                | `NSGlobalDomain com.apple.trackpad.scaling`                            | `defaults read -g com.apple.trackpad.scaling`     | `defaults write` |
| ☐   | Force Click / haptic          | `com.apple.AppleMultitouchTrackpad ActuateDetents`                     | `defaults read com.apple.AppleMultitouchTrackpad` | `defaults write` |
| ☐   | Silent clicking               | `com.apple.AppleMultitouchTrackpad SilentClick`                        | 同上                                              | 同上             |
| ☐   | Tap to click                  | `com.apple.AppleMultitouchTrackpad Clicking`                           | 同上                                              | 同上             |
| ☐   | Secondary click (right click) | `com.apple.AppleMultitouchTrackpad RightClicking`                      | 同上                                              | 同上             |
| ☐   | Look up & data detectors      | `com.apple.AppleMultitouchTrackpad TrackpadFourFingerVertSwipeGesture` | 同上                                              | 同上             |
| ☐   | Three finger drag             | `com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag`            | 同上                                              | 同上             |

### 二十三 B. Trackpad > Scroll & Zoom

| ☐   | 項目                       | defaults 鍵                                                           | 備份指令 |
| --- | -------------------------- | --------------------------------------------------------------------- | -------- |
| ☐   | Scroll direction (natural) | `-g com.apple.swipescrolldirection`                                   | 同 Mouse |
| ☐   | Zoom in / out (pinch)      | `com.apple.AppleMultitouchTrackpad TrackpadPinch`                     |
| ☐   | Smart zoom                 | `com.apple.AppleMultitouchTrackpad TrackpadTwoFingerDoubleTapGesture` |
| ☐   | Rotate                     | `com.apple.AppleMultitouchTrackpad TrackpadRotate`                    |

### 二十三 C. Trackpad > More Gestures

| ☐   | 項目                                       | defaults 鍵                           |
| --- | ------------------------------------------ | ------------------------------------- |
| ☐   | Mission Control (Multi-finger swipe up)    | `TrackpadFourFingerVertSwipeGesture`  |
| ☐   | App Exposé (Down swipe)                    | 同上                                  |
| ☐   | Swipe between pages                        | `TrackpadFourFingerHorizSwipeGesture` |
| ☐   | Launchpad (Pinch)                          | `TrackpadPinch` (另一個值)            |
| ☐   | Show Desktop (Spread)                      | `TrackpadSpread`                      |
| ☐   | Notification Center (Left swipe from edge) | `TrackpadRightEdge`                   |
| ☐   | Stage Manager / Quick Note                 | `TrackpadCornerSecondClick`           |

---

## 二十四、Printers & Scanners

開啟：System Settings → `Printers & Scanners`。

| ☐   | 項目             | 機制                              | 備份            |
| --- | ---------------- | --------------------------------- | --------------- |
| ☐   | 預設印表機       | `~/.cups/lpoptions` + `lpstat -p` | copy `~/.cups/` |
| ☐   | 印表機驅動 (PPD) | `/Library/Printers/PPDs/`         | sudo rsync      |
| ☐   | 自訂紙張 / 輸出  | `lpoptions -p <printer>`          | 匯出重新 add    |

---

## 二十五、Sidecar

開啟：System Settings → (視機種) Display / Sidecar。

| ☐   | 項目         | 機制                           |
| --- | ------------ | ------------------------------ |
| ☐   | Sidecar 偏好 | 無直接 plist，每次重連重新偵測 |

---

## 二十六、追加單獨存在項目 (其他容易漏)

| ☐   | 項目                                          | defaults 鍵                                                           | 備份指令                                             | 還原指令                     |
| --- | --------------------------------------------- | --------------------------------------------------------------------- | ---------------------------------------------------- | ---------------------------- |
| ☐   | Time Zone                                     | `systemsetup`                                                         | `sudo systemsetup -gettimezone`                      | ✗ (需 sudo + 反查 ID)        |
| ☐   | Date & Time (24-hour, show seconds)           | `com.apple.menuextra.clock DateFormat` 等                             | `defaults read com.apple.menuextra.clock`            | `defaults write`             |
| ☐   | Auto-correct / Capitalize / Period substitute | `NSGlobalDomain NSAutomaticSpellingCorrectionEnabled` 等              | `defaults read -g`                                   | `defaults write`             |
| ☐   | Smart Quotes / Dashes                         | `NSGlobalDomain NSAutomatic*`                                         | 同上                                                 | 同上                         |
| ☐   | Save documents to iCloud by default           | `NSGlobalDomain NSDocumentSaveNewDocumentsToCloud`                    | `defaults read -g NSDocumentSaveNewDocumentsToCloud` | `defaults write -bool true`  |
| ☐   | Close windows when quitting app               | `NSGlobalDomain NSQuitAlwaysKeepsWindows`                             | `defaults read -g NSQuitAlwaysKeepsWindows`          | `defaults write -bool false` |
| ☐   | Recent Items (5/10/15)                        | `NSGlobalDomain NSRecentDocumentsLimit`                               | `defaults read -g NSRecentDocumentsLimit`            | `defaults write -int 10`     |
| ☐   | Default web browser                           | `com.apple.launchservices/com.apple.launchservices.secure LSHandlers` | 整個 `LSHandlers` 字典                               | 整個字典                     |

---

## 二十七、全套 dump 一鍵化 (推薦做法)

```bash
# 全網域 export
mkdir -p ~/projects/env_setup/dump/defaults
for d in NSGlobalDomain com.apple.dock com.apple.finder com.apple.AppleMultitouchTrackpad \
         com.apple.Safari com.apple.Spotlight com.apple.Siri com.apple.LoginItemsPolicy \
         com.apple.symbolichotkeys com.apple.SoftwareUpdate com.apple.batterymode \
         com.apple.universalaccess com.apple.controlcenter com.apple.systempower \
         com.apple.doitnotdisturb com.apple.menuUI com.apple.TextInputMenuItems \
         com.apple.Terminal com.apple.ActivityMonitor com.apple.ScreenSaverChooser; do
    defaults export "$d" "$HOME/projects/env_setup/dump/defaults/${d}.plist" 2>/dev/null
done

# 應用程式容器 (白名單)
rsync -a --delete ~/Library/Application\ Support/iTerm2/ ~/projects/env_setup/dump/app-support/iTerm2/
rsync -a --delete ~/Library/Application\ Support/Rectangle/ ~/projects/env_setup/dump/app-support/Rectangle/
rsync -a --delete ~/Library/Application\ Support/Karabiner-Elements/ ~/projects/env_setup/dump/app-support/Karabiner-Elements/

# LaunchAgents
tar czf ~/projects/env_setup/dump/launchagents.tgz ~/Library/LaunchAgents/

# 全機 (sudo)
sudo tar czf ~/projects/env_setup/dump/system-launchdaemons.tgz /Library/LaunchDaemons/
sudo cp /etc/sudoers.d/* ~/projects/env_setup/dump/ 2>/dev/null
```

還原腳本 (反方向)：

```bash
for d in NSGlobalDomain com.apple.dock com.apple.finder ...; do
    defaults import "$d" "dump/defaults/${d}.plist" 2>/dev/null
done
killall Dock Finder
```

---

## 二十八、已驗證不可匯出 (硬限制)

| 類型                                      | 原因                      |
| ----------------------------------------- | ------------------------- |
| iCloud (Photos, Drive, Messages, Find My) | Apple ID 帳號綁           |
| Touch ID / Face ID                        | Secure Enclave 內         |
| FileVault recovery key                    | T2 / Apple Silicon 晶片綁 |
| Activation Lock                           | Apple ID 啟用鎖           |
| Apple Pay 卡片                            | 必須逐張重加              |
| App Store 授權                            | Apple ID + DRM            |
| Touch ID 啟動的 Keychain 條目             | 部分 lock                 |
| Wi-Fi 已知密碼                            | keychain 綁               |
| Time Machine 快照加密金鑰                 | keychain 綁               |

---

## 二十九、對 `env_setup` 補完建議 (對應本檔可打包 8 支腳本)

| 腳本                                   | 涵蓋                                                          |
| -------------------------------------- | ------------------------------------------------------------- |
| `bin/mac/defaults_dump.sh`             | 全部 `defaults` 網域批次 export                               |
| `bin/mac/defaults_restore.sh`          | 對應 import + `killall Dock Finder`                           |
| `bin/mac/app_support_sync.sh --backup` | rsync 白名單 (iTerm2, Rectangle, Karabiner, Stats, Raycast)   |
| `bin/mac/dock_layout_dump.sh`          | `persistent-apps` + `persistent-others` 解析，使用 `dockutil` |
| `bin/mac/dock_layout_restore.sh`       | 對應 `--add`                                                  |
| `bin/mac/launchagents_dump.sh`         | 打包 `~/Library/LaunchAgents/` 與 `/Library/LaunchDaemons/`   |
| `bin/mac/launchagents_restore.sh`      | 解包                                                          |
| `bin/mac/wallpaper_sync.sh`            | 整包 `~/Library/Application Support/com.apple.wallpaper/`     |

每一支預估 30~80 行 shell，可在 `env_setup` 內完工。

---

## 三十、相關檔案索引 (References)

- `bin/mac/mac_keyboard_shortcuts_dump.sh` — 已實作的 Symbolic Hotkeys + App Shortcuts 備份
- `bin/mac/mac_keyboard_shortcuts_restore.sh` — 已實作的還原腳本
- `bin/mac/launch_audit-mac.sh` — LaunchAgent / Daemon 稽核 (audit)
- `bin/mac/login_audit-mac.sh` — Login Items 稽核
- `bin/mac/mac_cleanup.sh` — Cache 與日誌批次清理
- `bin/mac/disk_analysis-mac.sh` — 磁碟使用分析
- `bin/mac/_lib_audit.sh` — 稽核腳本共用 helper (`term_log` / `md_log` / `audit_init`)
- `pkg/mac/globalp.plist` — 系統全域 plist 樣板
- `pkg/mac/LaunchAgents/` — LaunchAgent plist 樣板
- `pkg/mac/applescript/toggleFn.scpt` — Function key toggle AppleScript
