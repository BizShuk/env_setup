package main

import (
	"strings"
	"testing"
)

func TestGreetCmd(t *testing.T) {
	root := RootCmd()

	// Test default greeting
	out, err := executeCommand(root, "greet")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(out, "Hello, there!") {
		t.Errorf("expected output to contain 'Hello, there!', got %q", out)
	}

	// Test greeting with name
	out, err = executeCommand(root, "greet", "--name", "Shuk")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(out, "Hello, Shuk!") {
		t.Errorf("expected output to contain 'Hello, Shuk!', got %q", out)
	}
}
