module.exports = {
    apps: [
        {
            namespace: "Local",
            name: "Golang Clean Cache",
            script: "go",
            args: ["clean", "-cache"],
            cron: "0 10 * * 5"
        },
        // { // has problme with pm2
        //     namespace: "Infra",
        //     name: "Infra Compose",
        //     script: "docker",
        //     args: ["compose", "up"],
        //     config_dir: "~/.config/inf"
        // },
        {
            namespace: "Local",
            name: "Port Listenor",
            script: "port_listenor",
            args: ["monitor"],
            config_dir: "~/.config/port_listenor"
        },
        {
            namespace: "Local",
            name: "File Watcher",
            script: "file_watcher",
            args: ["monitor"],
            config_dir: "~/.config/file_watcher"
        },
        {
            namespace: "Local",
            name: "Disk Analysis",
            script: "./bin/mac/disk_analysis-mac.sh",
            cron: "0 5 * * 5"
        },
        {
            namespace: "Local",
            name: "Launch Audit",
            script: "./bin/mac/launch_audit-mac.sh",
            cron: "0 5 * * 5"
        },
        {
            namespace: "Local",
            name: "Login Audit",
            script: "./bin/mac/login_audit-mac.sh",
            cron: "0 5 * * 5"
        }
    ]
};
