package cleanup

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestPlanApplyDeletesOnlyDiscoveredTargets(t *testing.T) {
	root := t.TempDir()
	reviewedPath := filepath.Join(root, "reviewed.cache")
	if err := os.WriteFile(reviewedPath, []byte("reviewed"), 0o600); err != nil {
		t.Fatal(err)
	}

	service := New([]Definition{{
		ID:          "cache",
		Description: "清理 Cache",
		Selectors: []Selector{{
			Kind: SELECTOR_CONTENTS,
			Path: root,
		}},
	}}, NewOSRunner())
	plan, err := service.Inspect(context.Background())
	if err != nil {
		t.Fatal(err)
	}

	unreviewedPath := filepath.Join(root, "created-after-preview.cache")
	if err := os.WriteFile(unreviewedPath, []byte("keep"), 0o600); err != nil {
		t.Fatal(err)
	}

	if err := plan.Apply(context.Background(), "cache"); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(reviewedPath); !errors.Is(err, os.ErrNotExist) {
		t.Fatalf("reviewed target still exists or stat failed unexpectedly: %v", err)
	}
	if _, err := os.Stat(unreviewedPath); err != nil {
		t.Fatalf("unreviewed target should remain: %v", err)
	}
}

func TestPlanApplyRejectsUnknownItem(t *testing.T) {
	service := New(nil, NewOSRunner())
	plan, err := service.Inspect(context.Background())
	if err != nil {
		t.Fatal(err)
	}

	err = plan.Apply(context.Background(), "not-reviewed")
	if err == nil || err.Error() != `unknown cleanup item "not-reviewed"` {
		t.Fatalf("error = %v", err)
	}
}

func TestPlanApplyRunsCommandsInCatalogOrder(t *testing.T) {
	runner := &recordingRunner{
		available: map[string]bool{"first": true, "second": true},
	}
	service := New([]Definition{{
		ID:          "commands",
		Description: "清理 command caches",
		Commands: []Command{
			{Name: "first", Args: []string{"one"}},
			{Name: "second", Args: []string{"two", "three"}},
		},
	}}, runner)
	plan, err := service.Inspect(context.Background())
	if err != nil {
		t.Fatal(err)
	}

	if err := plan.Apply(context.Background(), "commands"); err != nil {
		t.Fatal(err)
	}
	want := [][]string{
		{"first", "one"},
		{"second", "two", "three"},
	}
	if !reflect.DeepEqual(runner.calls, want) {
		t.Fatalf("calls = %#v, want %#v", runner.calls, want)
	}
}

type recordingRunner struct {
	available map[string]bool
	calls     [][]string
}

func (r *recordingRunner) LookPath(file string) (string, error) {
	if r.available[file] {
		return file, nil
	}
	return "", errors.New("command not found")
}

func (r *recordingRunner) Run(_ context.Context, name string, args ...string) error {
	call := append([]string{name}, args...)
	r.calls = append(r.calls, call)
	return nil
}
