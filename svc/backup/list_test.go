package backup

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestWriteListHeaderShowsLatestBackupDate(t *testing.T) {
	dir := t.TempDir()
	data, err := json.Marshal(meta{Timestamp: "2026-07-15T17:31:09+08:00"})
	if err != nil {
		t.Fatalf("marshal metadata: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dir, "backup.meta.json"), data, 0o600); err != nil {
		t.Fatalf("write metadata: %v", err)
	}

	var output bytes.Buffer
	if err := writeListHeader(&output, "/tmp/manifest.json", dir); err != nil {
		t.Fatalf("writeListHeader() error: %v", err)
	}

	want := "manifest: /tmp/manifest.json\n" +
		"backup:   " + dir + "\n" +
		"latest:   2026-07-15 17:31:09 +08:00\n\n"
	if got := output.String(); got != want {
		t.Fatalf("writeListHeader() = %q, want %q", got, want)
	}
}
