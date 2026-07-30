package dump_test

import (
	"bytes"
	"context"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	dumpcmd "github.com/bizshuk/env_setup/cmd/dump"
	dumpsvc "github.com/bizshuk/env_setup/svc/dump"
)

func TestCommandContainsManifestDumpCommands(t *testing.T) {
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: newCommandRepository(t),
		GOOS:          "darwin",
		Runner:        &commandRunner{},
		LookPath:      commandLookPath,
	})
	command := dumpcmd.NewCommand(service, &bytes.Buffer{}, &bytes.Buffer{})

	for _, name := range []string{"mac", "vscode", "antigravity"} {
		found, remaining, err := command.Find([]string{name})
		if err != nil {
			t.Errorf("find %q: %v", name, err)
			continue
		}
		if len(remaining) != 0 {
			t.Errorf("find %q left arguments %v", name, remaining)
			continue
		}
		if found.Name() != name {
			t.Errorf("find %q returned %q", name, found.Name())
		}
	}
}

func TestVSCodeCommandExecutesDump(t *testing.T) {
	repositoryDir := newCommandRepository(t)
	runner := &commandRunner{
		outputs: map[string]string{"code --list-extensions": "z.publisher\nA.publisher\n"},
	}
	service := dumpsvc.New(dumpsvc.Options{
		RepositoryDir: repositoryDir,
		GOOS:          "darwin",
		Runner:        runner,
		LookPath:      commandLookPath,
	})
	command := dumpcmd.NewCommand(service, &bytes.Buffer{}, &bytes.Buffer{})
	command.SetArgs([]string{"vscode"})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}
	content, err := os.ReadFile(filepath.Join(
		repositoryDir,
		"bin",
		"vscode",
		"vscode_extension_list.txt",
	))
	if err != nil {
		t.Fatal(err)
	}
	if got, want := string(content), "A.publisher\nz.publisher\n"; got != want {
		t.Fatalf("manifest = %q, want %q", got, want)
	}
}

func newCommandRepository(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	if err := os.MkdirAll(filepath.Join(root, "scripts"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(root, "bin", "vscode"), 0o755); err != nil {
		t.Fatal(err)
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

func commandLookPath(name string) (string, error) {
	return "/usr/bin/" + name, nil
}

type commandRunner struct {
	outputs map[string]string
	calls   []string
}

func (r *commandRunner) Run(
	_ context.Context,
	_ io.Reader,
	out io.Writer,
	_ io.Writer,
	name string,
	args ...string,
) error {
	key := strings.Join(append([]string{name}, args...), " ")
	r.calls = append(r.calls, key)
	_, err := io.WriteString(out, r.outputs[key])
	return err
}
