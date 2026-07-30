package cleanup

import (
	"bytes"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	cleanupsvc "github.com/bizshuk/env_setup/svc/cleanup"
)

func TestCleanupPreviewListsItemsWithoutPromptOrApply(t *testing.T) {
	target := filepath.Join(t.TempDir(), "cache.bin")
	if err := os.WriteFile(target, []byte("12345"), 0o600); err != nil {
		t.Fatal(err)
	}
	service := cleanupsvc.New([]cleanupsvc.Definition{{
		ID:          "test-cache",
		Description: "清除測試 Cache",
		Selectors:   []cleanupsvc.Selector{{Kind: cleanupsvc.SELECTOR_PATH, Path: target}},
	}}, cleanupsvc.NewCommandRunner())
	var output bytes.Buffer

	command := NewCommand(service, strings.NewReader("y\n"), &output)
	command.SetArgs([]string{})
	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}

	got := output.String()
	for _, want := range []string{"ID", "SIZE", "DESCRIPTION", "test-cache", "5 B", "清除測試 Cache"} {
		if !strings.Contains(got, want) {
			t.Errorf("output does not contain %q:\n%s", want, got)
		}
	}
	if strings.Contains(got, "[y/N]") {
		t.Fatalf("preview must not prompt:\n%s", got)
	}
	if _, err := os.Stat(target); err != nil {
		t.Fatalf("preview changed target: %v", err)
	}
}

func TestCleanupApplyConfirmsOneByOne(t *testing.T) {
	root := t.TempDir()
	first := filepath.Join(root, "first.cache")
	second := filepath.Join(root, "second.cache")
	if err := os.WriteFile(first, []byte("first"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(second, []byte("second"), 0o600); err != nil {
		t.Fatal(err)
	}
	service := cleanupsvc.New([]cleanupsvc.Definition{
		{
			ID:          "first",
			Description: "清除第一個 Cache",
			Selectors:   []cleanupsvc.Selector{{Kind: cleanupsvc.SELECTOR_PATH, Path: first}},
		},
		{
			ID:          "second",
			Description: "清除第二個 Cache",
			Selectors:   []cleanupsvc.Selector{{Kind: cleanupsvc.SELECTOR_PATH, Path: second}},
		},
	}, cleanupsvc.NewCommandRunner())
	var output bytes.Buffer

	command := NewCommand(service, strings.NewReader("y\nn\n"), &output)
	command.SetArgs([]string{"--apply"})
	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}

	if _, err := os.Stat(first); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("confirmed item was not removed: %v", err)
	}
	if _, err := os.Stat(second); err != nil {
		t.Fatalf("declined item should remain: %v", err)
	}
	if got := strings.Count(output.String(), "[y/N]"); got != 2 {
		t.Fatalf("prompt count = %d, want 2:\n%s", got, output.String())
	}
}
