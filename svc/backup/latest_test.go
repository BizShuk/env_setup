package backup

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestLatestBackupDateUsesMetadataTimestamp(t *testing.T) {
	dir := t.TempDir()
	wantTime := time.Date(2026, time.July, 15, 17, 31, 9, 0, time.FixedZone("UTC+8", 8*60*60))
	data, err := json.Marshal(meta{Timestamp: wantTime.Format(time.RFC3339)})
	if err != nil {
		t.Fatalf("marshal metadata: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dir, "backup.meta.json"), data, 0o600); err != nil {
		t.Fatalf("write metadata: %v", err)
	}

	plistPath := filepath.Join(dir, "com.example.newer.plist")
	if err := os.WriteFile(plistPath, []byte("plist"), 0o600); err != nil {
		t.Fatalf("write plist: %v", err)
	}
	newerTime := wantTime.Add(24 * time.Hour)
	if err := os.Chtimes(plistPath, newerTime, newerTime); err != nil {
		t.Fatalf("set plist modification time: %v", err)
	}

	got, err := latestBackupDate(dir)
	if err != nil {
		t.Fatalf("latestBackupDate() error: %v", err)
	}
	want := "2026-07-15 17:31:09 +08:00"
	if got != want {
		t.Fatalf("latestBackupDate() = %q, want %q", got, want)
	}
}

func TestLatestBackupDateFallsBackToNewestPlistModificationTime(t *testing.T) {
	dir := t.TempDir()
	older := time.Date(2026, time.June, 1, 8, 0, 0, 0, time.FixedZone("UTC+8", 8*60*60))
	newer := older.Add(48 * time.Hour)
	newestNonPlist := newer.Add(24 * time.Hour)

	writeFileWithModificationTime(t, filepath.Join(dir, "older.plist"), older)
	writeFileWithModificationTime(t, filepath.Join(dir, "newer.plist"), newer)
	writeFileWithModificationTime(t, filepath.Join(dir, "notes.txt"), newestNonPlist)

	got, err := latestBackupDate(dir)
	if err != nil {
		t.Fatalf("latestBackupDate() error: %v", err)
	}
	want := "2026-06-03 08:00:00 +08:00"
	if got != want {
		t.Fatalf("latestBackupDate() = %q, want %q", got, want)
	}
}

func TestLatestBackupDateShowsDashWhenNoBackupExists(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "missing")

	got, err := latestBackupDate(dir)
	if err != nil {
		t.Fatalf("latestBackupDate() error: %v", err)
	}
	if got != "-" {
		t.Fatalf("latestBackupDate() = %q, want %q", got, "-")
	}
}

func writeFileWithModificationTime(t *testing.T, path string, modifiedAt time.Time) {
	t.Helper()
	if err := os.WriteFile(path, []byte("fixture"), 0o600); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
	if err := os.Chtimes(path, modifiedAt, modifiedAt); err != nil {
		t.Fatalf("set modification time for %s: %v", path, err)
	}
}
