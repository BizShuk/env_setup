package uninstall_test

import (
	"context"
	"errors"
	"io"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	uninstallsvc "github.com/bizshuk/env_setup/svc/uninstall"
)

func TestInspectCodexRejectsNonDarwin(t *testing.T) {
	service := uninstallsvc.New(uninstallsvc.Options{
		GOOS:    "linux",
		HomeDir: t.TempDir(),
	})

	_, err := service.InspectCodex(t.Context(), uninstallsvc.CodexOptions{})

	if err == nil || !strings.Contains(err.Error(), "macOS") {
		t.Fatalf("error = %v, want macOS-only rejection", err)
	}
}

func TestInspectCodexDiscoversExactDefaultTargets(t *testing.T) {
	paths := newUninstallTestPaths(t)
	mustCreateDirectory(t, filepath.Join(paths.applications, "Codex.app"))
	mustCreateFile(t, filepath.Join(paths.home, ".local", "bin", "codex"))
	mustCreateDirectory(t, filepath.Join(paths.home, ".codex"))
	mustCreateDirectory(t, filepath.Join(
		paths.home,
		"Library",
		"Application Support",
		"Codex",
	))
	cachePath := filepath.Join(
		paths.home,
		"Library",
		"Caches",
		"com.openai.codex.renderer",
	)
	mustCreateDirectory(t, cachePath)
	preferencePath := filepath.Join(
		paths.home,
		"Library",
		"Preferences",
		"com.openai.codex.plist",
	)
	mustCreateFile(t, preferencePath)
	mustCreateDirectory(t, filepath.Join(paths.applications, "CodexBar.app"))
	systemPath := filepath.Join(
		paths.systemLibrary,
		"LaunchAgents",
		"com.openai.codex.system.plist",
	)
	mustCreateFile(t, systemPath)
	mustCreateDirectory(t, filepath.Join(paths.etc, "codex"))

	runner := &uninstallRunner{outputs: map[string]string{
		uninstallCommandKey("launchctl", "list"): strings.Join([]string{
			"123\t0\tcom.openai.codex.helper",
			"456\t0\tcom.example.other",
			"",
		}, "\n"),
	}}
	service := newUninstallService(paths, runner, uninstallLookPath("launchctl"))

	plan, err := service.InspectCodex(t.Context(), uninstallsvc.CodexOptions{})
	if err != nil {
		t.Fatal(err)
	}

	targets := availableTargets(plan.Items())
	for _, target := range []string{
		filepath.Join(paths.applications, "Codex.app"),
		filepath.Join(paths.home, ".local", "bin", "codex"),
		filepath.Join(paths.home, ".codex"),
		filepath.Join(paths.home, "Library", "Application Support", "Codex"),
		cachePath,
		preferencePath,
		"com.openai.codex.helper",
	} {
		if !slices.Contains(targets, target) {
			t.Errorf("available targets = %v, want %q", targets, target)
		}
	}
	for _, excluded := range []string{
		filepath.Join(paths.applications, "CodexBar.app"),
		systemPath,
		filepath.Join(paths.etc, "codex"),
		"com.example.other",
	} {
		if slices.Contains(targets, excluded) {
			t.Errorf("available targets = %v, do not want %q", targets, excluded)
		}
	}
}

func TestInspectCodexIncludesOptInTargets(t *testing.T) {
	paths := newUninstallTestPaths(t)
	codexBarPath := filepath.Join(paths.applications, "CodexBar.app")
	systemAgentPath := filepath.Join(
		paths.systemLibrary,
		"LaunchAgents",
		"com.openai.codex.agent.plist",
	)
	systemDaemonPath := filepath.Join(
		paths.systemLibrary,
		"LaunchDaemons",
		"com.openai.codex.daemon.plist",
	)
	etcPath := filepath.Join(paths.etc, "codex")
	mustCreateDirectory(t, codexBarPath)
	mustCreateFile(t, systemAgentPath)
	mustCreateFile(t, systemDaemonPath)
	mustCreateDirectory(t, etcPath)
	service := newUninstallService(paths, &uninstallRunner{}, uninstallLookPath())

	plan, err := service.InspectCodex(t.Context(), uninstallsvc.CodexOptions{
		WithCodexBar: true,
		PurgeSystem:  true,
	})
	if err != nil {
		t.Fatal(err)
	}

	targets := availableTargets(plan.Items())
	for _, target := range []string{
		codexBarPath,
		systemAgentPath,
		systemDaemonPath,
		etcPath,
	} {
		if !slices.Contains(targets, target) {
			t.Errorf("available targets = %v, want opt-in target %q", targets, target)
		}
	}
}

func TestCodexPlanApplyUsesOnlyInspectedFilesystemTarget(t *testing.T) {
	paths := newUninstallTestPaths(t)
	inspectedPath := filepath.Join(
		paths.home,
		"Library",
		"Caches",
		"com.openai.codex.first",
	)
	latePath := filepath.Join(
		paths.home,
		"Library",
		"Caches",
		"com.openai.codex.late",
	)
	otherPath := filepath.Join(paths.home, ".codex")
	mustCreateDirectory(t, inspectedPath)
	mustCreateDirectory(t, otherPath)
	service := newUninstallService(paths, &uninstallRunner{}, uninstallLookPath())

	plan, err := service.InspectCodex(t.Context(), uninstallsvc.CodexOptions{})
	if err != nil {
		t.Fatal(err)
	}
	itemID := availableItemID(t, plan.Items(), inspectedPath)
	mustCreateDirectory(t, latePath)

	if err := plan.Apply(t.Context(), itemID, io.Discard, io.Discard); err != nil {
		t.Fatal(err)
	}

	assertPathAbsent(t, inspectedPath)
	assertPathPresent(t, latePath)
	assertPathPresent(t, otherPath)
}

func TestCodexPlanApplyUsesArgumentSafeExternalCommandsAndQuitsOnce(t *testing.T) {
	paths := newUninstallTestPaths(t)
	systemPath := filepath.Join(
		paths.systemLibrary,
		"LaunchAgents",
		"com.openai.codex.system.plist",
	)
	mustCreateFile(t, systemPath)
	label := "com.openai.codex.helper;touch-pwned"
	runner := &uninstallRunner{
		outputs: map[string]string{
			uninstallCommandKey("launchctl", "list"): "123\t0\t" + label + "\n",
		},
		errors: map[string]error{
			uninstallCommandKey("osascript", "-e", `quit app "Codex"`): errors.New("not running"),
		},
	}
	service := newUninstallService(
		paths,
		runner,
		uninstallLookPath("launchctl", "osascript"),
	)

	plan, err := service.InspectCodex(t.Context(), uninstallsvc.CodexOptions{
		PurgeSystem: true,
	})
	if err != nil {
		t.Fatal(err)
	}
	labelID := availableItemID(t, plan.Items(), label)
	systemID := availableItemID(t, plan.Items(), systemPath)

	if err := plan.Apply(t.Context(), labelID, io.Discard, io.Discard); err != nil {
		t.Fatal(err)
	}
	if err := plan.Apply(t.Context(), systemID, io.Discard, io.Discard); err != nil {
		t.Fatal(err)
	}

	want := []uninstallCall{
		{name: "launchctl", args: []string{"list"}},
		{name: "osascript", args: []string{"-e", `quit app "Codex"`}},
		{
			name: "launchctl",
			args: []string{"bootout", "gui/501/" + label},
		},
		{
			name: "sudo",
			args: []string{"rm", "-rf", "--", systemPath},
		},
	}
	if !slices.EqualFunc(runner.calls, want, equalUninstallCall) {
		t.Fatalf("runner calls = %#v, want %#v", runner.calls, want)
	}
}

type uninstallTestPaths struct {
	home          string
	applications  string
	systemLibrary string
	etc           string
}

func newUninstallTestPaths(t *testing.T) uninstallTestPaths {
	t.Helper()

	root := t.TempDir()
	paths := uninstallTestPaths{
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
		mustCreateDirectory(t, path)
	}
	return paths
}

func newUninstallService(
	paths uninstallTestPaths,
	runner uninstallsvc.Runner,
	lookPath func(string) (string, error),
) *uninstallsvc.Service {
	return uninstallsvc.New(uninstallsvc.Options{
		HomeDir:         paths.home,
		ApplicationsDir: paths.applications,
		SystemLibrary:   paths.systemLibrary,
		EtcDir:          paths.etc,
		GOOS:            "darwin",
		Runner:          runner,
		LookPath:        lookPath,
		CurrentUID: func() int {
			return 501
		},
	})
}

func availableTargets(items []uninstallsvc.Item) []string {
	var targets []string
	for _, item := range items {
		if item.Available {
			targets = append(targets, item.Target)
		}
	}
	return targets
}

func availableItemID(t *testing.T, items []uninstallsvc.Item, target string) string {
	t.Helper()
	for _, item := range items {
		if item.Available && item.Target == target {
			return item.ID
		}
	}
	t.Fatalf("no available item for target %q in %#v", target, items)
	return ""
}

func mustCreateDirectory(t *testing.T, path string) {
	t.Helper()
	if err := os.MkdirAll(path, 0o755); err != nil {
		t.Fatal(err)
	}
}

func mustCreateFile(t *testing.T, path string) {
	t.Helper()
	mustCreateDirectory(t, filepath.Dir(path))
	if err := os.WriteFile(path, []byte("test"), 0o644); err != nil {
		t.Fatal(err)
	}
}

func assertPathPresent(t *testing.T, path string) {
	t.Helper()
	if _, err := os.Lstat(path); err != nil {
		t.Fatalf("stat %s: %v", path, err)
	}
}

func assertPathAbsent(t *testing.T, path string) {
	t.Helper()
	if _, err := os.Lstat(path); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("stat %s error = %v, want not exist", path, err)
	}
}

func uninstallLookPath(available ...string) func(string) (string, error) {
	return func(name string) (string, error) {
		if slices.Contains(available, name) {
			return "/usr/bin/" + name, nil
		}
		return "", errors.New("not found")
	}
}

type uninstallCall struct {
	name string
	args []string
}

type uninstallRunner struct {
	outputs map[string]string
	errors  map[string]error
	calls   []uninstallCall
}

func (r *uninstallRunner) Run(
	_ context.Context,
	_ io.Reader,
	out io.Writer,
	_ io.Writer,
	name string,
	args ...string,
) error {
	r.calls = append(r.calls, uninstallCall{
		name: name,
		args: append([]string(nil), args...),
	})
	key := uninstallCommandKey(name, args...)
	if err := r.errors[key]; err != nil {
		return err
	}
	_, err := io.WriteString(out, r.outputs[key])
	return err
}

func uninstallCommandKey(name string, args ...string) string {
	return strings.Join(append([]string{name}, args...), " ")
}

func equalUninstallCall(left, right uninstallCall) bool {
	return left.name == right.name && slices.Equal(left.args, right.args)
}
