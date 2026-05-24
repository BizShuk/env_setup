package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestConfigCmd(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "config_test")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	configPathOverride = filepath.Join(tmpDir, "test_config.json")
	root := RootCmd()

	// Test config set
	_, err = executeCommand(root, "config", "set", "--key", "theme", "--value", "dark")
	if err != nil {
		t.Fatalf("unexpected error setting config: %v", err)
	}

	// Test config get
	out, err := executeCommand(root, "config", "get", "--key", "theme")
	if err != nil {
		t.Fatalf("unexpected error getting config: %v", err)
	}
	if !strings.Contains(out, "theme = dark") {
		t.Errorf("expected output to contain 'theme = dark', got %q", out)
	}

	// Test config get missing key
	out, err = executeCommand(root, "config", "get", "--key", "nonexistent")
	if err != nil {
		t.Fatalf("unexpected error getting nonexistent config: %v", err)
	}
	if !strings.Contains(out, "Key 'nonexistent' not found") {
		t.Errorf("expected not found message, got %q", out)
	}
}
