package version_test

import (
	"strings"
	"testing"

	"golang-scratch/internal/version"
)

func TestStringContainsVersion(t *testing.T) {
	got := version.String()
	if !strings.Contains(got, version.Version) {
		t.Fatalf("String() = %q, want substring %q", got, version.Version)
	}
	if !strings.HasPrefix(got, "golang-scratch ") {
		t.Fatalf("String() = %q, want prefix %q", got, "golang-scratch ")
	}
}
