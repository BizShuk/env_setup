package main

import (
	"bytes"
	"strings"
	"testing"

	"github.com/spf13/cobra"
)

func executeCommand(root *cobra.Command, args ...string) (string, error) {
	buf := new(bytes.Buffer)
	root.SetOut(buf)
	root.SetErr(buf)
	root.SetArgs(args)
	err := root.Execute()
	return buf.String(), err
}

func TestCalcCmd(t *testing.T) {
	root := RootCmd()

	// Test add operation
	out, err := executeCommand(root, "calc", "--num1", "10", "--num2", "5", "--operation", "add")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(out, "Result: 15") {
		t.Errorf("expected output to contain 'Result: 15', got %q", out)
	}

	// Test sub operation
	out, err = executeCommand(root, "calc", "--num1", "10", "--num2", "5", "--operation", "sub")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(out, "Result: 5") {
		t.Errorf("expected output to contain 'Result: 5', got %q", out)
	}

	// Test invalid operation
	_, err = executeCommand(root, "calc", "--num1", "10", "--num2", "5", "--operation", "invalid")
	if err == nil {
		t.Fatal("expected error, got nil")
	}
	if !strings.Contains(err.Error(), "invalid operation") {
		t.Errorf("expected error message to contain 'invalid operation', got %v", err)
	}
}
