package server_test

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"golang-scratch/internal/server"
	"golang-scratch/internal/version"
)

func TestHealthz(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rr := httptest.NewRecorder()
	server.NewMux().ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusOK)
	}
	body, _ := io.ReadAll(rr.Body)
	if strings.TrimSpace(string(body)) != "ok" {
		t.Fatalf("body = %q, want %q", body, "ok")
	}
}

func TestHello(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rr := httptest.NewRecorder()
	server.NewMux().ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusOK)
	}
	body, _ := io.ReadAll(rr.Body)
	got := strings.TrimSpace(string(body))
	if got != version.String() {
		t.Fatalf("body = %q, want %q", got, version.String())
	}
}
