package backup

import (
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
)

// defaultManifest 是內建的預設網域清單,首次執行時種入 config 目錄。
//
//go:embed mac_backup_domains.default.json
var defaultManifest []byte

// Domain 為一個 `defaults` 設定網域及其人類可讀說明。
type Domain struct {
	Domain string `json:"domain"`
	Note   string `json:"note,omitempty"`
}

// LoadManifest 讀取使用者網域清單;若不存在則以內建預設值種入後回傳。
func LoadManifest() ([]Domain, error) {
	p := ManifestPath()
	data, err := os.ReadFile(p)
	if errors.Is(err, os.ErrNotExist) {
		if err := SeedManifest(); err != nil {
			return nil, err
		}
		data = defaultManifest
	} else if err != nil {
		return nil, fmt.Errorf("read manifest %s: %w", p, err)
	}

	var domains []Domain
	if err := json.Unmarshal(data, &domains); err != nil {
		return nil, fmt.Errorf("parse manifest %s: %w", p, err)
	}
	if len(domains) == 0 {
		return nil, fmt.Errorf("manifest %s is empty", p)
	}
	return domains, nil
}

// SeedManifest 把內建預設清單寫入 config 目錄 (不覆寫既有檔案)。
func SeedManifest() error {
	p := ManifestPath()
	if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
		return err
	}
	if _, err := os.Stat(p); err == nil {
		return nil // 已存在,不覆寫使用者編輯
	}
	if err := os.WriteFile(p, defaultManifest, 0o644); err != nil {
		return fmt.Errorf("seed manifest %s: %w", p, err)
	}
	return nil
}
