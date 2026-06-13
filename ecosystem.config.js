module.exports = {
    apps: [
        {
            namespace: "Local",
            name: "Golang Clean Cache",
            script: "go",
            args: ["clean", "-cache"],
            cron: "0 10 * * 5",
            autorestart: false
        }
    ]
};
