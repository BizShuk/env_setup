package cleanup

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestInspectListsDescriptionAndRecursiveSize(t *testing.T) {
	root := t.TempDir()
	nested := filepath.Join(root, "nested")
	if err := os.Mkdir(nested, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "first.bin"), []byte("12345"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(nested, "second.bin"), []byte("678"), 0o600); err != nil {
		t.Fatal(err)
	}

	service := New([]Definition{{
		ID:          "cache",
		Description: "清理測試 Cache",
		Selectors: []Selector{{
			Kind: SELECTOR_CONTENTS,
			Path: root,
		}},
	}}, NewCommandRunner())

	plan, err := service.Inspect(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	items := plan.Items()
	if len(items) != 1 {
		t.Fatalf("items length = %d, want 1", len(items))
	}
	if items[0].Description != "清理測試 Cache" {
		t.Fatalf("description = %q", items[0].Description)
	}
	if items[0].SizeBytes != 8 {
		t.Fatalf("size = %d, want 8", items[0].SizeBytes)
	}
	if !items[0].SizeKnown {
		t.Fatal("size should be known")
	}
	if !items[0].Available {
		t.Fatal("item should be available")
	}
}

func TestInspectOlderFilesKeepsRecentFilesOutOfPlan(t *testing.T) {
	root := t.TempDir()
	oldPath := filepath.Join(root, "old.log")
	recentPath := filepath.Join(root, "recent.log")
	if err := os.WriteFile(oldPath, []byte("old"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(recentPath, []byte("recent"), 0o600); err != nil {
		t.Fatal(err)
	}
	oldTime := time.Now().Add(-31 * 24 * time.Hour)
	if err := os.Chtimes(oldPath, oldTime, oldTime); err != nil {
		t.Fatal(err)
	}

	service := New([]Definition{{
		ID:          "old-cache",
		Description: "清理 30 天前 Cache",
		Selectors: []Selector{{
			Kind:          SELECTOR_OLDER_FILES,
			Path:          root,
			OlderThanDays: 30,
		}},
	}}, NewCommandRunner())

	plan, err := service.Inspect(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	items := plan.Items()
	if len(items) != 1 {
		t.Fatalf("items length = %d, want 1", len(items))
	}
	if items[0].SizeBytes != 3 {
		t.Fatalf("size = %d, want old file size 3", items[0].SizeBytes)
	}
	if !items[0].Available {
		t.Fatal("old file item should be available")
	}
}

func TestInspectSkipsTemporaryDirectoryInUseByAProcess(t *testing.T) {
	root := t.TempDir()
	target := filepath.Join(root, "active-cache")
	if err := os.Mkdir(target, 0o700); err != nil {
		t.Fatal(err)
	}
	runner := &inUseRunner{}
	service := New([]Definition{{
		ID:          "active-cache",
		Description: "清除 active Cache",
		Selectors: []Selector{{
			Kind:      SELECTOR_PATH,
			Path:      target,
			SkipInUse: true,
		}},
	}}, runner)

	plan, err := service.Inspect(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	item := plan.Items()[0]
	if item.Available {
		t.Fatal("in-use directory must not be available")
	}
	if runner.lsofCalls != 1 {
		t.Fatalf("lsof calls = %d, want 1", runner.lsofCalls)
	}
}

type inUseRunner struct {
	lsofCalls int
}

func (r *inUseRunner) LookPath(file string) (string, error) {
	if file == "lsof" {
		return "/usr/sbin/lsof", nil
	}
	return "", errors.New("command not found")
}

func (r *inUseRunner) Run(_ context.Context, name string, _ ...string) error {
	if name == "lsof" {
		r.lsofCalls++
		return nil
	}
	return errors.New("unexpected command")
}
