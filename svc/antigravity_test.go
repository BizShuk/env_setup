package svc_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/bizshuk/env_setup/svc"
)

func TestAntigravityExtensionsDirPrefersOverride(t *testing.T) {
	t.Setenv(svc.AntigravityExtensionsDirEnv, "/custom/extensions")
	t.Setenv("HOME", t.TempDir())

	if got, want := svc.AntigravityExtensionsDir(), "/custom/extensions"; got != want {
		t.Fatalf("extensions directory = %q, want %q", got, want)
	}
}

func TestAntigravityExtensionsDirTargetsRemoteServerHost(t *testing.T) {
	home := newAntigravityHome(t, filepath.Join(".antigravity-ide-server", "data", "User"))

	want := filepath.Join(home, ".antigravity-ide-server", "extensions")
	if got := svc.AntigravityExtensionsDir(); got != want {
		t.Fatalf("extensions directory = %q, want %q", got, want)
	}
}

func TestAntigravityExtensionsDirKeepsCLIDefaultForDesktopHost(t *testing.T) {
	newAntigravityHome(
		t,
		filepath.Join(".antigravity-ide", "User"),
		filepath.Join(".antigravity-ide-server", "data", "User"),
	)

	if got := svc.AntigravityExtensionsDir(); got != "" {
		t.Fatalf("extensions directory = %q, want CLI default", got)
	}
}

func TestAntigravityExtensionsDirKeepsCLIDefaultWithoutAntigravity(t *testing.T) {
	newAntigravityHome(t)

	if got := svc.AntigravityExtensionsDir(); got != "" {
		t.Fatalf("extensions directory = %q, want CLI default", got)
	}
}

func newAntigravityHome(t *testing.T, directories ...string) string {
	t.Helper()

	home := t.TempDir()
	t.Setenv(svc.AntigravityExtensionsDirEnv, "")
	t.Setenv("HOME", home)
	for _, directory := range directories {
		if err := os.MkdirAll(filepath.Join(home, directory), 0o755); err != nil {
			t.Fatal(err)
		}
	}
	return home
}
