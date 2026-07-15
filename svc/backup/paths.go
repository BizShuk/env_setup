// Package backup 為服務層 (service):與 macOS `defaults`/`plutil` 互動,
// 並實作設定網域 (domain) 的 backup / import(override) 邏輯。
//
// 路徑沿用 gosdk config 慣例,呼叫端須先 config.Default(WithAppName(...))。
package backup

import (
	"path/filepath"

	"github.com/bizshuk/gosdk/config"
)

// BackupDir 回傳 backup 檔案落點 ~/.config/env_setup/data/backup/mac。
func BackupDir() string {
	return filepath.Join(config.GetAppDataDir(), "backup", "mac")
}

// ManifestPath 回傳可編輯的網域清單路徑 ~/.config/env_setup/mac_backup_domains.json。
func ManifestPath() string {
	return filepath.Join(config.GetAppConfigDir(), "mac_backup_domains.json")
}

// backupFile 回傳指定網域的 backup 檔案路徑。
func backupFile(domain string) string {
	return filepath.Join(BackupDir(), domain+".plist")
}
