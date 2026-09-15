module.exports = {
    apps: [
        // { // has problme with pm2
        //     namespace: "Local",
        //     name: "Infra Compose",
        //     script: "docker",
        //     args: ["compose", "up"]
        // },
        // ⚠️ Port Listenor / File Watcher 需先實作對應 bin/port_listenor 與 bin/file_watcher
        // 暫停常駐任務 (dead config), 待工具到位後改用 ./bin/<area>/<tool> 全路徑
        // {
        //     namespace: "Local",
        //     name: "Port Listenor",
        //     script: "port_listenor",
        //     args: ["monitor"]
        // },
        // {
        //     namespace: "Local",
        //     name: "File Watcher",
        //     script: "file_watcher",
        //     args: ["monitor"]
        // },
        // 本機 Ollama LLM 服務 (常駐背景執行)：提供本地大語言模型推理服務 (keep-alive 5m, 單一模型)
        {
            namespace: "Agent",
            name: "Ollama",
            script: "ollama",
            args: ["serve"],
            instances: 1,
            env: {
                OLLAMA_KEEP_ALIVE: "5m",
                OLLAMA_MAX_LOADED_MODELS: "1"
            }
        },
        // 系統健康探測 (週一 04:00)：每週一開工前聚合探測 CPU、記憶體、作業系統、GPU、螢幕、音訊與實體介面狀態
        {
            namespace: "Local",
            name: "System Health Probe",
            script: "./scripts/system/show.sh",
            cron: "0 4 * * 1"
        },
        // 能耗與喚醒探測 (每日 10:00/14:00/18:00/22:00)：取樣耗能排行與喚醒風暴，找出低 CPU 卻高喚醒的耗電來源
        // 刻意排在工作時段而非其他稽核的凌晨時段：機器在 04:00 是閒置或睡眠狀態，量到的耗電排行沒有意義
        {
            namespace: "Local",
            name: "Energy Wakeup Probe",
            script: "./scripts/system/energy.sh",
            args: ["--interval", "10", "--top", "20"],
            cron: "0 10,14,18,22 * * *"
        },
        // 實體儲存裝置探測 (週一 05:00)：探測本機實體磁碟、NVMe/SATA/USB 傳輸介面、型號與掛載點
        {
            namespace: "Local",
            name: "Storage Device Probe",
            script: "./scripts/io/probe.sh",
            cron: "0 5 * * 1"
        },
        // 備份狀態稽核 (週二 04:30)：檢查 macOS defaults 偏好設定之最新快照時間戳與備份檔案完整性
        {
            namespace: "Local",
            name: "Backup Status Audit",
            script: "./scripts/backup/list.sh",
            cron: "30 4 * * 2"
        },
        // 私有路由拓撲掃描 (週三 04:00)：以 traceroute 探測公網第 1 跳並對沿途私有子網段執行 host discovery
        {
            namespace: "Local",
            name: "Private Route Topology",
            script: "./scripts/network/private.sh",
            cron: "0 4 * * 3"
        },
        // 網路安全稽核 (週四 04:00)：檢查 macOS 防火牆狀態、監聽通訊埠、網路共享服務並產出 markdown 報告
        {
            namespace: "Local",
            name: "Network Security Audit",
            script: "./bin/mac/network_security_audit-mac.sh",
            cron: "0 4 * * 4"
        },
        // 系統啟動項目稽核 (週五 04:00)：檢查 macOS LaunchDaemons 與 LaunchAgents 之設定、狀態與簽名並產出報告
        {
            namespace: "Local",
            name: "Launch Audit",
            script: "./bin/mac/launch_audit-mac.sh",
            cron: "0 4 * * 5"
        },
        // 使用者登入項目稽核 (週五 04:30)：檢查本機使用者登入自啟項目 (Login Items) 與背景背景程式並產出報告
        {
            namespace: "Local",
            name: "Login Audit",
            script: "./bin/mac/login_audit-mac.sh",
            cron: "30 4 * * 5"
        },
        // 磁碟清理預覽 (週六 05:00)：週末前自動預覽系統日誌、暫存檔、Docker、套件快取等可回收磁碟空間 (safe preview，不執行刪除)
        {
            namespace: "Local",
            name: "Disk Cleanup Preview",
            script: "./scripts/cleanup/all.sh",
            cron: "0 5 * * 6"
        }
    ]
};
