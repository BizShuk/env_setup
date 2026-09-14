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
        {
            namespace: "Local",
            name: "System Health Probe",
            script: "./scripts/system/show.sh",
            cron: "0 4 * * 1"
        },
        {
            namespace: "Local",
            name: "Storage Device Probe",
            script: "./scripts/io/probe.sh",
            cron: "0 5 * * 1"
        },
        {
            namespace: "Local",
            name: "Backup Status Audit",
            script: "./scripts/backup/list.sh",
            cron: "30 4 * * 2"
        },
        {
            namespace: "Local",
            name: "Private Route Topology",
            script: "./scripts/network/private.sh",
            cron: "0 4 * * 3"
        },
        {
            namespace: "Local",
            name: "Network Security Audit",
            script: "./bin/mac/network_security_audit-mac.sh",
            cron: "0 4 * * 4"
        },
        {
            namespace: "Local",
            name: "Launch Audit",
            script: "./bin/mac/launch_audit-mac.sh",
            cron: "0 4 * * 5"
        },
        {
            namespace: "Local",
            name: "Login Audit",
            script: "./bin/mac/login_audit-mac.sh",
            cron: "30 4 * * 5"
        },
        {
            namespace: "Local",
            name: "Disk Cleanup Preview",
            script: "./scripts/cleanup/all.sh",
            cron: "0 5 * * 6"
        }
    ]
};
