package main

import (
	"strings"
	"testing"
)

func TestHelloCmd(t *testing.T) {
	root := RootCmd()
	out, err := executeCommand(root, "hello")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(out, "Hello, world!") {
		t.Errorf("expected output to contain 'Hello, world!', got %q", out)
	}
}
