package system

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"strings"
	"testing"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
)

func TestDiskVerifyDefaultsToNo(t *testing.T) {
	runner := &diskVerifyCommandRunner{}
	service := systemsvc.New(systemsvc.Options{
		GOOS:   "darwin",
		Runner: runner,
		LookPath: func(name string) (string, error) {
			return "/usr/bin/" + name, nil
		},
	})
	var out bytes.Buffer
	command := NewCommand(service, &out, &bytes.Buffer{})
	command.SetIn(strings.NewReader("\n"))
	command.SetArgs([]string{"disk", "verify", "/Volumes/backup"})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}
	if len(runner.calls) != 0 {
		t.Fatalf("runner calls = %v, want none", runner.calls)
	}
	if !strings.Contains(out.String(), "略過 F3 disk verification") {
		t.Fatalf("output = %q, want skipped message", out.String())
	}
}

func TestDiskVerifyCommandExists(t *testing.T) {
	service := systemsvc.New(systemsvc.Options{GOOS: "darwin", Runner: &diskVerifyCommandRunner{}})
	command := NewCommand(service, &bytes.Buffer{}, &bytes.Buffer{})

	found, remaining, err := command.Find([]string{"disk", "verify"})
	if err != nil {
		t.Fatal(err)
	}
	if len(remaining) != 0 {
		t.Fatalf("remaining arguments = %v, want none", remaining)
	}
	if found.Name() != "verify" {
		t.Fatalf("command name = %q, want verify", found.Name())
	}
}

func TestDiskVerifyYesRunsVerification(t *testing.T) {
	runner := &diskVerifyCommandRunner{}
	service := systemsvc.New(systemsvc.Options{
		GOOS:   "darwin",
		Runner: runner,
		LookPath: func(name string) (string, error) {
			return "/usr/bin/" + name, nil
		},
	})
	var out bytes.Buffer
	command := NewCommand(service, &out, &bytes.Buffer{})
	command.SetArgs([]string{"disk", "verify", "/Volumes/backup", "--yes"})

	if err := command.Execute(); err != nil {
		t.Fatal(err)
	}
	wantCalls := []string{
		"diskutil info /Volumes/backup",
		"f3write /Volumes/backup",
		"f3read /Volumes/backup",
	}
	if fmt.Sprint(runner.calls) != fmt.Sprint(wantCalls) {
		t.Fatalf("runner calls = %v, want %v", runner.calls, wantCalls)
	}
}

type diskVerifyCommandRunner struct {
	calls []string
}

func (r *diskVerifyCommandRunner) Run(
	_ context.Context,
	_ io.Reader,
	_ io.Writer,
	_ io.Writer,
	name string,
	args ...string,
) error {
	r.calls = append(r.calls, strings.Join(append([]string{name}, args...), " "))
	return nil
}
