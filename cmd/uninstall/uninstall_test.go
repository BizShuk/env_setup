package uninstall_test

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	uninstallcmd "github.com/bizshuk/env_setup/cmd/uninstall"
	uninstallsvc "github.com/bizshuk/env_setup/svc/uninstall"
)

func TestCommandContainsOnlyCodexCommand(t *testing.T) {
	service, _ := newUninstallCommandService(t)
	command := uninstallcmd.NewCommand(
		service,
		strings.NewReader(""),
		io.Discard,
		io.Discard,
	)

	found, remaining, err := command.Find([]string{"codex"})
	if err != nil {
		t.Fatal(err)
	}
	if len(remaining) != 0 {
		t.Fatalf("remaining arguments = %v, want none", remaining)
	}
	if got, want := found.Name(), "codex"; got != want {
		t.Fatalf("found command = %q, want %q", got, want)
	}
	if got, want := len(command.Commands()), 1; got != want {
		t.Fatalf("child command count = %d, want %d", got, want)
	}
}

func TestCodexCommandDefaultsToPreview(t *testing.T) {
	service, paths := newUninstallCommandService(t)
	cliPath := filepath.Join(paths.home, ".local", "bin", "codex")
	dataPath := filepath.Join(paths.home, ".codex")
	mustCreateCommandFile(t, cliPath)
	mustCreateCommandDirectory(t, dataPath)
	var output bytes.Buffer
	command := uninstallcmd.NewCommand(
		service,
		strings.NewReader(""),
		&output,
		io.Discard,
	)
	command.SetArgs([]string{"codex"})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}

	assertCommandPathPresent(t, cliPath)
	assertCommandPathPresent(t, dataPath)
	if !strings.Contains(output.String(), "Preview mode") {
		t.Fatalf("output = %q, want preview notice", output.String())
	}
	if !strings.Contains(output.String(), "env_setup uninstall codex --apply") {
		t.Fatalf("output = %q, want apply instructions", output.String())
	}
}

func TestCodexCommandApplyConfirmsEachAvailableItem(t *testing.T) {
	service, paths := newUninstallCommandService(t)
	cliPath := filepath.Join(paths.home, ".local", "bin", "codex")
	dataPath := filepath.Join(paths.home, ".codex")
	mustCreateCommandFile(t, cliPath)
	mustCreateCommandDirectory(t, dataPath)
	var output bytes.Buffer
	command := uninstallcmd.NewCommand(
		service,
		strings.NewReader("yes\nn\n"),
		&output,
		io.Discard,
	)
	command.SetArgs([]string{"codex", "--apply"})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}

	assertCommandPathAbsent(t, cliPath)
	assertCommandPathPresent(t, dataPath)
	if !strings.Contains(output.String(), "applied=1 skipped=1 failed=0") {
		t.Fatalf("output = %q, want apply summary", output.String())
	}
}

type uninstallCommandPaths struct {
	home          string
	applications  string
	systemLibrary string
	etc           string
}

func newUninstallCommandService(
	t *testing.T,
) (*uninstallsvc.Service, uninstallCommandPaths) {
	t.Helper()

	root := t.TempDir()
	paths := uninstallCommandPaths{
		home:          filepath.Join(root, "home"),
		applications:  filepath.Join(root, "Applications"),
		systemLibrary: filepath.Join(root, "Library"),
		etc:           filepath.Join(root, "etc"),
	}
	for _, path := range []string{
		paths.home,
		paths.applications,
		paths.systemLibrary,
		paths.etc,
	} {
		mustCreateCommandDirectory(t, path)
	}
	service := uninstallsvc.New(uninstallsvc.Options{
		HomeDir:         paths.home,
		ApplicationsDir: paths.applications,
		SystemLibrary:   paths.systemLibrary,
		EtcDir:          paths.etc,
		GOOS:            "darwin",
		Runner:          uninstallCommandRunner{},
		LookPath: func(string) (string, error) {
			return "", errors.New("not found")
		},
		CurrentUID: func() int {
			return 501
		},
	})
	return service, paths
}

type uninstallCommandRunner struct{}

func (uninstallCommandRunner) Run(
	context.Context,
	io.Reader,
	io.Writer,
	io.Writer,
	string,
	...string,
) error {
	return nil
}

func mustCreateCommandDirectory(t *testing.T, path string) {
	t.Helper()
	if err := os.MkdirAll(path, 0o755); err != nil {
		t.Fatal(err)
	}
}

func mustCreateCommandFile(t *testing.T, path string) {
	t.Helper()
	mustCreateCommandDirectory(t, filepath.Dir(path))
	if err := os.WriteFile(path, []byte("test"), 0o755); err != nil {
		t.Fatal(err)
	}
}

func assertCommandPathPresent(t *testing.T, path string) {
	t.Helper()
	if _, err := os.Lstat(path); err != nil {
		t.Fatalf("stat %s: %v", path, err)
	}
}

func assertCommandPathAbsent(t *testing.T, path string) {
	t.Helper()
	if _, err := os.Lstat(path); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("stat %s error = %v, want not exist", path, err)
	}
}
