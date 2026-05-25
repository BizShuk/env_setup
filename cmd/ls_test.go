package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLsCmd(t *testing.T) {
	tmpDir, err := os.MkdirTemp("", "ls_test")
	if err != nil {
		t.Fatalf("failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create test files
	file1 := filepath.Join(tmpDir, "file1.txt")
	file2 := filepath.Join(tmpDir, "file2.txt")
	if err := os.WriteFile(file1, []byte(""), 0644); err != nil {
		t.Fatalf("failed to write file1: %v", err)
	}
	if err := os.WriteFile(file2, []byte(""), 0644); err != nil {
		t.Fatalf("failed to write file2: %v", err)
	}

	root := RootCmd()

	// Test successful ls
	out, err := executeCommand(root, "ls", "--path", tmpDir)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(out, "file1.txt") || !strings.Contains(out, "file2.txt") {
		t.Errorf("expected output to contain file1.txt and file2.txt, got %q", out)
	}

	// Test ls nonexistent directory (should return error)
	_, err = executeCommand(root, "ls", "--path", filepath.Join(tmpDir, "nonexistent"))
	if err == nil {
		t.Error("expected error for nonexistent directory, got nil")
	}
}
