package main

import (
	"strings"
	"testing"
)

func TestListCmd(t *testing.T) {
	root := RootCmd()
	out, err := executeCommand(root, "list")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	expectedCommands := []string{
		"Available Commands:",
		"- hello",
		"- greet",
		"- calc",
		"- fetch",
		"- ls",
		"- config",
		"- list",
	}

	for _, cmd := range expectedCommands {
		if !strings.Contains(out, cmd) {
			t.Errorf("expected output to contain %q, got %q", cmd, out)
		}
	}
}
