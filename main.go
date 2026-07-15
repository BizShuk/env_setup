// Command env_setup/macbackup 備份 / 匯入 (override) macOS `defaults` 設定網域 (domain)。
//
// 分層 (Layering):
//
//	main.go       組合根 (composition root):初始化 gosdk config,委派給 cmd/backup
//	cmd/backup    命令清單 (CLI command list):子指令分派與旗標解析
//	svc/backup    服務層 (service):與 macOS `defaults`/`plutil` 互動 + backup/import 邏輯
//
// 資料落點沿用 gosdk config 慣例:
//
//	backup 檔案 -> ~/.config/env_setup/data/backup/mac/<domain>.plist
//	網域清單    -> ~/.config/env_setup/mac_backup_domains.json (首次執行自動種入)
package main

import (
	"os"

	cmdbackup "github.com/bizshuk/env_setup/cmd/backup"
	"github.com/bizshuk/gosdk/config"
)

const APP_NAME = "env_setup"

func main() {
	// 初始化 gosdk config,使 GetAppDataDir() / GetAppConfigDir() 指向 ~/.config/env_setup。
	config.Default(config.WithAppName(APP_NAME))

	os.Exit(cmdbackup.Execute(os.Args[1:]))
}
