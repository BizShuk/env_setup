package install_test

import (
	"context"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	installcmd "github.com/bizshuk/env_setup/cmd/install"
	installsvc "github.com/bizshuk/env_setup/svc/install"
)

func TestCommandContainsAntigravityExtensionCommand(t *testing.T) {
	command := installcmd.NewCommand(
		newInstallCommandService(t, &installCommandRunner{}),
		strings.NewReader(""),
		io.Discard,
		io.Discard,
	)

	found, remaining, err := command.Find([]string{"antigravity-extension"})
	if err != nil {
		t.Fatal(err)
	}
	if len(remaining) != 0 {
		t.Fatalf("remaining arguments = %v, want none", remaining)
	}
	if got, want := found.Name(), "antigravity-extension"; got != want {
		t.Fatalf("found command = %q, want %q", got, want)
	}
	if got, want := len(command.Commands()), 2; got != want {
		t.Fatalf("child command count = %d, want %d", got, want)
	}
}

func TestAntigravityExtensionCommandExecutesInstall(t *testing.T) {
	runner := &installCommandRunner{outputs: map[string]string{
		"agy-ide --list-extensions": "A.publisher\n",
	}}
	command := installcmd.NewCommand(
		newInstallCommandService(t, runner),
		strings.NewReader(""),
		io.Discard,
		io.Discard,
	)
	command.SetArgs([]string{"antigravity-extension"})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}

	want := []string{
		"agy-ide --install-extension A.publisher --force",
		"agy-ide --list-extensions",
	}
	if strings.Join(runner.calls, "\n") != strings.Join(want, "\n") {
		t.Fatalf("runner calls = %v, want %v", runner.calls, want)
	}
}

func TestVSCodeExtensionCommandExecutesInstall(t *testing.T) {
	runner := &installCommandRunner{outputs: map[string]string{
		"code --list-extensions": "A.publisher\n",
	}}
	command := installcmd.NewCommand(
		newInstallCommandService(t, runner),
		strings.NewReader(""),
		io.Discard,
		io.Discard,
	)
	command.SetArgs([]string{"vscode-extension"})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}

	want := []string{
		"code --install-extension A.publisher --force",
		"code --list-extensions",
	}
	if strings.Join(runner.calls, "\n") != strings.Join(want, "\n") {
		t.Fatalf("runner calls = %v, want %v", runner.calls, want)
	}
}

func newInstallCommandService(t *testing.T, runner installsvc.Runner) *installsvc.Service {
	t.Helper()

	repositoryDir := t.TempDir()
	manifestDir := filepath.Join(repositoryDir, "bin", "vscode")
	if err := os.MkdirAll(manifestDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(
		filepath.Join(repositoryDir, "go.mod"),
		[]byte("module github.com/bizshuk/env_setup\n"),
		0o644,
	); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(
		filepath.Join(manifestDir, "agy-ide_extension_list.txt"),
		[]byte("A.publisher\n"),
		0o644,
	); err != nil {
		t.Fatal(err)
	}
	return installsvc.New(installsvc.Options{
		RepositoryDir: repositoryDir,
		Runner:        runner,
		LookPath: func(name string) (string, error) {
			return "/usr/bin/" + name, nil
		},
	})
}

type installCommandRunner struct {
	outputs map[string]string
	calls   []string
}

func (r *installCommandRunner) Run(
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
