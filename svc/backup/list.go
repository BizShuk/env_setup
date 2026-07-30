package backup

import (
	"fmt"
	"io"
	"os"
)

// List 顯示網域清單、最新備份日期與每個網域的 backup 狀態。
func List(w io.Writer) error {
	domains, err := LoadManifest()
	if err != nil {
		return err
	}
	if err := writeListHeader(w, ManifestPath(), BackupDir()); err != nil {
		return err
	}

	fmt.Fprintf(w, "%-8s %-8s %s\n", "BACKUP", "LIVE", "DOMAIN")
	for _, domain := range domains {
		backupStatus := "-"
		if _, err := os.Stat(backupFile(domain.Domain)); err == nil {
			backupStatus = "yes"
		}
		liveStatus := "-"
		if domainExists(domain.Domain) {
			liveStatus = "yes"
		}
		fmt.Fprintf(w, "%-8s %-8s %s\n", backupStatus, liveStatus, domain.Domain)
	}
	return nil
}

func writeListHeader(w io.Writer, manifestPath, backupDir string) error {
	latest, err := latestBackupDate(backupDir)
	if err != nil {
		return fmt.Errorf("find latest backup date: %w", err)
	}
	fmt.Fprintf(
		w,
		"manifest: %s\nbackup:   %s\nlatest:   %s\n\n",
		manifestPath,
		backupDir,
		latest,
	)
	return nil
}
