package backup

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

const latestBackupDateLayout = "2006-01-02 15:04:05 -07:00"

func latestBackupDate(dir string) (string, error) {
	path := filepath.Join(dir, "backup.meta.json")
	data, err := os.ReadFile(path)
	if err == nil {
		return backupDateFromMetadata(path, data)
	}
	if !errors.Is(err, os.ErrNotExist) {
		return "", fmt.Errorf("read backup metadata %s: %w", path, err)
	}

	timestamp, found, err := latestPlistModificationTime(dir)
	if err != nil {
		return "", err
	}
	if !found {
		return "-", nil
	}
	return timestamp.Format(latestBackupDateLayout), nil
}

func backupDateFromMetadata(path string, data []byte) (string, error) {
	var metadata meta
	if err := json.Unmarshal(data, &metadata); err != nil {
		return "", fmt.Errorf("parse backup metadata %s: %w", path, err)
	}
	timestamp, err := time.Parse(time.RFC3339, metadata.Timestamp)
	if err != nil {
		return "", fmt.Errorf("parse backup timestamp %q: %w", metadata.Timestamp, err)
	}
	return timestamp.Format(latestBackupDateLayout), nil
}

func latestPlistModificationTime(dir string) (time.Time, bool, error) {
	entries, err := os.ReadDir(dir)
	if errors.Is(err, os.ErrNotExist) {
		return time.Time{}, false, nil
	}
	if err != nil {
		return time.Time{}, false, fmt.Errorf("read backup directory %s: %w", dir, err)
	}

	var latest time.Time
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".plist" {
			continue
		}
		info, err := entry.Info()
		if err != nil {
			return time.Time{}, false, fmt.Errorf("read backup file info %s: %w", entry.Name(), err)
		}
		if info.ModTime().After(latest) {
			latest = info.ModTime()
		}
	}
	return latest, !latest.IsZero(), nil
}
