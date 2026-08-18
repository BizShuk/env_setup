package dump_test

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	dumpsvc "github.com/bizshuk/env_setup/svc/dump"
)

func TestDumpMacRunsBrewBundleDump(t *testing.T) {
	repositoryDir := newRepository(t)
	runner := &fakeRunner{}
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: repositoryDir,
		GOOS:          "darwin",
		Runner:        runner,
		LookPath:      availableLookPath,
	})
	var out bytes.Buffer

	if err := service.DumpMac(context.Background(), &out, &bytes.Buffer{}); err != nil {
		t.Fatal(err)
	}

	want := commandKey(
		"brew",
		"bundle",
		"dump",
		"--force",
		"--file="+filepath.Join(repositoryDir, "scripts", "Brewfile"),
	)
	if got := fmt.Sprint(runner.calls); got != fmt.Sprint([]string{want}) {
		t.Fatalf("runner calls = %v, want %v", runner.calls, []string{want})
	}
	if !strings.Contains(out.String(), filepath.Join("scripts", "Brewfile")) {
		t.Fatalf("output = %q, want Brewfile path", out.String())
	}
}

func TestDumpMacRejectsNonDarwin(t *testing.T) {
	runner := &fakeRunner{}
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: newRepository(t),
		GOOS:          "linux",
		Runner:        runner,
		LookPath:      availableLookPath,
	})

	err := service.DumpMac(context.Background(), &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "requires macOS") {
		t.Fatalf("error = %v, want macOS requirement", err)
	}
	if len(runner.calls) != 0 {
		t.Fatalf("runner calls = %v, want none", runner.calls)
	}
}

func TestDumpRejectsDifferentRepository(t *testing.T) {
	repositoryDir := t.TempDir()
	if err := os.WriteFile(
		filepath.Join(repositoryDir, "go.mod"),
		[]byte("module example.com/other\n"),
		0o644,
	); err != nil {
		t.Fatal(err)
	}
	runner := &fakeRunner{}
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: repositoryDir,
		GOOS:          "darwin",
		Runner:        runner,
		LookPath:      availableLookPath,
	})

	err := service.DumpMac(context.Background(), &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "is not the github.com/bizshuk/env_setup repository root") {
		t.Fatalf("error = %v, want repository root rejection", err)
	}
	if len(runner.calls) != 0 {
		t.Fatalf("runner calls = %v, want none", runner.calls)
	}
}

func TestDumpVSCodeWritesSortedUniqueManifest(t *testing.T) {
	repositoryDir := newRepository(t)
	runner := &fakeRunner{outputs: map[string]string{
		commandKey("code", "--list-extensions"): "z.publisher\nA.publisher\nz.publisher\n\n",
	}}
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: repositoryDir,
		GOOS:          "darwin",
		Runner:        runner,
		LookPath:      availableLookPath,
	})

	if err := service.DumpVSCode(
		context.Background(),
		&bytes.Buffer{},
		&bytes.Buffer{},
	); err != nil {
		t.Fatal(err)
	}

	path := filepath.Join(repositoryDir, "bin", "vscode", "vscode_extension_list.txt")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if got, want := string(content), "A.publisher\nz.publisher\n"; got != want {
		t.Fatalf("manifest = %q, want %q", got, want)
	}
}

func TestDumpAntigravityListsResolvedExtensionsDirectory(t *testing.T) {
	repositoryDir := newRepository(t)
	runner := &fakeRunner{outputs: map[string]string{
		commandKey(
			"agy-ide",
			"--extensions-dir",
			"/srv/extensions",
			"--list-extensions",
		): "golang.go\n",
	}}
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: repositoryDir,
		ExtensionsDir: "/srv/extensions",
		GOOS:          "linux",
		Runner:        runner,
		LookPath:      availableLookPath,
	})

	if err := service.DumpAntigravity(
		context.Background(),
		&bytes.Buffer{},
		&bytes.Buffer{},
	); err != nil {
		t.Fatal(err)
	}

	path := filepath.Join(repositoryDir, "bin", "vscode", "agy-ide_extension_list.txt")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if got, want := string(content), "golang.go\n"; got != want {
		t.Fatalf("manifest = %q, want %q", got, want)
	}
}

func TestDumpAntigravityWritesManifest(t *testing.T) {
	repositoryDir := newRepository(t)
	runner := &fakeRunner{outputs: map[string]string{
		commandKey("agy-ide", "--list-extensions"): "google.geminicodeassist\ngolang.go\n",
	}}
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: repositoryDir,
		GOOS:          "darwin",
		Runner:        runner,
		LookPath:      availableLookPath,
	})

	if err := service.DumpAntigravity(
		context.Background(),
		&bytes.Buffer{},
		&bytes.Buffer{},
	); err != nil {
		t.Fatal(err)
	}

	path := filepath.Join(repositoryDir, "bin", "vscode", "agy-ide_extension_list.txt")
	content, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if got, want := string(content), "golang.go\ngoogle.geminicodeassist\n"; got != want {
		t.Fatalf("manifest = %q, want %q", got, want)
	}
}

func TestDumpVSCodePreservesManifestWhenCommandFails(t *testing.T) {
	repositoryDir := newRepository(t)
	path := filepath.Join(repositoryDir, "bin", "vscode", "vscode_extension_list.txt")
	if err := os.WriteFile(path, []byte("existing.publisher\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	runner := &fakeRunner{errors: map[string]error{
		commandKey("code", "--list-extensions"): errors.New("code failed"),
	}}
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: repositoryDir,
		GOOS:          "darwin",
		Runner:        runner,
		LookPath:      availableLookPath,
	})

	err := service.DumpVSCode(context.Background(), &bytes.Buffer{}, &bytes.Buffer{})
	if err == nil || !strings.Contains(err.Error(), "code --list-extensions") {
		t.Fatalf("error = %v, want code command context", err)
	}
	content, readErr := os.ReadFile(path)
	if readErr != nil {
		t.Fatal(readErr)
	}
	if got, want := string(content), "existing.publisher\n"; got != want {
		t.Fatalf("manifest = %q, want preserved %q", got, want)
	}
}

func TestDumpChecksExecutableBeforeWriting(t *testing.T) {
	repositoryDir := newRepository(t)
	runner := &fakeRunner{}
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: repositoryDir,
		GOOS:          "darwin",
		Runner:        runner,
		LookPath: func(_ string) (string, error) {
			return "", errors.New("not found")
		},
	})

	err := service.DumpAntigravity(
		context.Background(),
		&bytes.Buffer{},
		&bytes.Buffer{},
	)
	if err == nil || !strings.Contains(err.Error(), `required command "agy-ide"`) {
		t.Fatalf("error = %v, want missing agy-ide", err)
	}
	if len(runner.calls) != 0 {
		t.Fatalf("runner calls = %v, want none", runner.calls)
	}
}

func newRepository(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	for _, path := range []string{
		filepath.Join(root, "scripts"),
		filepath.Join(root, "bin", "vscode"),
	} {
		if err := os.MkdirAll(path, 0o755); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(
		filepath.Join(root, "go.mod"),
		[]byte("module github.com/bizshuk/env_setup\n"),
		0o644,
	); err != nil {
		t.Fatal(err)
	}
	return root
}

func availableLookPath(name string) (string, error) {
	return "/usr/bin/" + name, nil
}

type fakeRunner struct {
	outputs map[string]string
	errors  map[string]error
	calls   []string
}

func (r *fakeRunner) Run(
	_ context.Context,
	_ io.Reader,
	out io.Writer,
	_ io.Writer,
	name string,
	args ...string,
) error {
	key := commandKey(name, args...)
	r.calls = append(r.calls, key)
	if err := r.errors[key]; err != nil {
		return err
	}
	_, err := io.WriteString(out, r.outputs[key])
	return err
}

func commandKey(name string, args ...string) string {
	return strings.Join(append([]string{name}, args...), " ")
}
