package backup

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

// meta 描述一次 backup 的產出資訊,寫入 backup 目錄供 list / import 參考。
type meta struct {
	Timestamp string   `json:"timestamp"`
	Host      string   `json:"host"`
	Domains   []string `json:"domains"`
}

// Backup 匯出網域清單內每個存在的網域到 backup 目錄。輸出寫到 w。
func Backup(w io.Writer) error {
	domains, err := LoadManifest()
	if err != nil {
		return err
	}

	dir := BackupDir()
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}

	fmt.Fprintf(w, "備份 macOS 設定 -> %s\n\n", dir)

	var saved []string
	for _, d := range domains {
		if !domainExists(d.Domain) {
			fmt.Fprintf(w, "  skip  %-52s (本機無此網域)\n", d.Domain)
			continue
		}
		if err := exportDomain(d.Domain, backupFile(d.Domain)); err != nil {
			fmt.Fprintf(w, "  fail  %-52s %v\n", d.Domain, err)
			continue
		}
		fmt.Fprintf(w, "  ok    %-52s %s\n", d.Domain, d.Note)
		saved = append(saved, d.Domain)
	}

	if err := writeMeta(dir, saved); err != nil {
		return err
	}
	fmt.Fprintf(w, "\n完成:%d 個網域已備份。\n", len(saved))
	return nil
}

// writeMeta 寫入 backup.meta.json。
func writeMeta(dir string, domains []string) error {
	host, _ := os.Hostname()
	m := meta{
		Timestamp: time.Now().Format(time.RFC3339),
		Host:      host,
		Domains:   domains,
	}
	data, err := json.MarshalIndent(m, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(filepath.Join(dir, "backup.meta.json"), data, 0o644)
}

// Init 只把預設網域清單種入 config 目錄。
func Init(w io.Writer) error {
	if err := SeedManifest(); err != nil {
		return err
	}
	fmt.Fprintf(w, "網域清單已就緒:%s\n", ManifestPath())
	return nil
}
