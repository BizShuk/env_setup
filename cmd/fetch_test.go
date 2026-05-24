package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestFetchCmd(t *testing.T) {
	// Start a local HTTP server
	server := httptest.NewServer(http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		rw.Write([]byte("mock content"))
	}))
	defer server.Close()

	root := RootCmd()

	// Test successful fetch
	out, err := executeCommand(root, "fetch", "--url", server.URL)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if !strings.Contains(out, "mock content") {
		t.Errorf("expected output to contain 'mock content', got %q", out)
	}

	// Test fetch fail (bad URL)
	out, err = executeCommand(root, "fetch", "--url", "http://invalid-url-that-does-not-exist.local")
	if !strings.Contains(out, "Error fetching URL") {
		t.Errorf("expected error message in output, got %q (err: %v)", out, err)
	}
}
