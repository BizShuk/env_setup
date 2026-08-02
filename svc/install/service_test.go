package install_test

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	installsvc "github.com/bizshuk/env_setup/svc/install"
)

func TestInstallAntigravityExtensionsInstallsManifestAndKeepsUnlistedOnDecline(t *testing.T) {
	repositoryDir := newInstallRepository(t, "z.publisher\nA.publisher\nz.publisher\n\n")
	runner := &installRunner{outputs: map[string]string{
		installCommandKey("agy-ide", "--list-extensions"): "A.publisher\nz.publisher\nextra.publisher\n",
	}}
	service := installsvc.New(installsvc.Options{
		RepositoryDir: repositoryDir,
		Runner:        runner,
		LookPath:      installLookPath,
	})
	var output bytes.Buffer

	err := service.InstallAntigravityExtensions(
		t.Context(),
		strings.NewReader("n\n"),
		&output,
		&bytes.Buffer{},
	)
	if err != nil {
		t.Fatal(err)
	}

	want := []string{
		installCommandKey("agy-ide", "--install-extension", "z.publisher", "--force"),
		installCommandKey("agy-ide", "--install-extension", "A.publisher", "--force"),
		installCommandKey("agy-ide", "--list-extensions"),
	}
	assertInstallCalls(t, runner.calls, want)
	if !strings.Contains(output.String(), "extra.publisher") {
		t.Fatalf("output = %q, want unlisted extension preview", output.String())
	}
}

func TestInstallAntigravityExtensionsRemovesUnlistedAfterConfirmation(t *testing.T) {
	repositoryDir := newInstallRepository(t, "A.publisher\n")
	runner := &installRunner{outputs: map[string]string{
		installCommandKey("agy-ide", "--list-extensions"): "A.publisher\nextra.one\nextra.two\n",
	}}
	service := installsvc.New(installsvc.Options{
		RepositoryDir: repositoryDir,
		Runner:        runner,
		LookPath:      installLookPath,
	})

	err := service.InstallAntigravityExtensions(
		t.Context(),
		strings.NewReader("Y\n"),
		io.Discard,
		io.Discard,
	)
	if err != nil {
		t.Fatal(err)
	}

	want := []string{
		installCommandKey("agy-ide", "--install-extension", "A.publisher", "--force"),
		installCommandKey("agy-ide", "--list-extensions"),
		installCommandKey("agy-ide", "--uninstall-extension", "extra.one"),
		installCommandKey("agy-ide", "--uninstall-extension", "extra.two"),
	}
	assertInstallCalls(t, runner.calls, want)
}

func TestInstallVSCodeExtensionsInstallsManifest(t *testing.T) {
	repositoryDir := newInstallRepository(t, "A.publisher\n")
	runner := &installRunner{outputs: map[string]string{
		installCommandKey("code", "--list-extensions"): "A.publisher\n",
	}}
	service := installsvc.New(installsvc.Options{
		RepositoryDir: repositoryDir,
		Runner:        runner,
		LookPath:      installLookPath,
	})

	err := service.InstallVSCodeExtensions(
		t.Context(),
		strings.NewReader(""),
		io.Discard,
		io.Discard,
	)
	if err != nil {
		t.Fatal(err)
	}

	want := []string{
		installCommandKey("code", "--install-extension", "A.publisher", "--force"),
		installCommandKey("code", "--list-extensions"),
	}
	assertInstallCalls(t, runner.calls, want)
}

func TestInstallAntigravityExtensionsRequiresExecutable(t *testing.T) {
	runner := &installRunner{}
	service := installsvc.New(installsvc.Options{
		RepositoryDir: newInstallRepository(t, "A.publisher\n"),
		Runner:        runner,
		LookPath: func(string) (string, error) {
			return "", errors.New("not found")
		},
	})

	err := service.InstallAntigravityExtensions(
		t.Context(),
		strings.NewReader(""),
		io.Discard,
		io.Discard,
	)

	if err == nil || !strings.Contains(err.Error(), `required command "agy-ide"`) {
		t.Fatalf("error = %v, want missing agy-ide", err)
	}
	assertInstallCalls(t, runner.calls, nil)
}

func TestInstallAntigravityExtensionsRejectsEmptyManifest(t *testing.T) {
	runner := &installRunner{}
	service := installsvc.New(installsvc.Options{
		RepositoryDir: newInstallRepository(t, "\n \n"),
		Runner:        runner,
		LookPath:      installLookPath,
	})

	err := service.InstallAntigravityExtensions(
		t.Context(),
		strings.NewReader(""),
		io.Discard,
		io.Discard,
	)

	if err == nil || !strings.Contains(err.Error(), "contains no extensions") {
		t.Fatalf("error = %v, want empty manifest rejection", err)
	}
	assertInstallCalls(t, runner.calls, nil)
}

func newInstallRepository(t *testing.T, manifest string) string {
	t.Helper()

	root := t.TempDir()
	manifestDir := filepath.Join(root, "bin", "vscode")
	if err := os.MkdirAll(manifestDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(
		filepath.Join(root, "go.mod"),
		[]byte("module github.com/bizshuk/env_setup\n"),
		0o644,
	); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(
		filepath.Join(manifestDir, "agy-ide_extension_list.txt"),
		[]byte(manifest),
		0o644,
	); err != nil {
		t.Fatal(err)
	}
	return root
}

func installLookPath(name string) (string, error) {
	return "/usr/bin/" + name, nil
}

type installRunner struct {
	outputs map[string]string
	errors  map[string]error
	calls   []string
}

func (r *installRunner) Run(
	_ context.Context,
	_ io.Reader,
	out io.Writer,
	_ io.Writer,
	name string,
	args ...string,
) error {
	key := installCommandKey(name, args...)
	r.calls = append(r.calls, key)
	if err := r.errors[key]; err != nil {
		return err
	}
	_, err := io.WriteString(out, r.outputs[key])
	return err
}

func installCommandKey(name string, args ...string) string {
	return strings.Join(append([]string{name}, args...), " ")
}

func assertInstallCalls(t *testing.T, got, want []string) {
	t.Helper()
	if strings.Join(got, "\n") != strings.Join(want, "\n") {
		t.Fatalf("runner calls = %v, want %v", got, want)
	}
}
