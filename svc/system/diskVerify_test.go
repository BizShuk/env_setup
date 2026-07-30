package system

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"
)

func TestVerifyDiskRunsDiskutilAndF3InOrder(t *testing.T) {
	runner := &fakeRunner{outputs: map[string]string{
		commandKey("diskutil", "info", "/Volumes/backup"): "Volume Name: backup\n",
		commandKey("f3write", "/Volumes/backup"):          "Free space: 10 GB\n",
		commandKey("f3read", "/Volumes/backup"):           "Data OK: 10 GB\n",
	}}
	service := New(Options{
		GOOS:   "darwin",
		Runner: runner,
		LookPath: func(name string) (string, error) {
			return "/usr/bin/" + name, nil
		},
	})
	var out bytes.Buffer

	if err := service.VerifyDisk(
		context.Background(),
		"/Volumes/backup",
		&out,
		&bytes.Buffer{},
	); err != nil {
		t.Fatal(err)
	}

	wantCalls := []string{
		commandKey("diskutil", "info", "/Volumes/backup"),
		commandKey("f3write", "/Volumes/backup"),
		commandKey("f3read", "/Volumes/backup"),
	}
	if fmt.Sprint(runner.calls) != fmt.Sprint(wantCalls) {
		t.Fatalf("runner calls = %v, want %v", runner.calls, wantCalls)
	}
	for _, want := range []string{
		"Volume Name: backup",
		"Free space: 10 GB",
		"Data OK: 10 GB",
	} {
		if !strings.Contains(out.String(), want) {
			t.Errorf("output = %q, want %q", out.String(), want)
		}
	}
}

func TestVerifyDiskRejectsNonDarwin(t *testing.T) {
	runner := &fakeRunner{}
	service := New(Options{
		GOOS:   "linux",
		Runner: runner,
		LookPath: func(name string) (string, error) {
			return "/usr/bin/" + name, nil
		},
	})

	err := service.VerifyDisk(
		context.Background(),
		"/media/backup",
		&bytes.Buffer{},
		&bytes.Buffer{},
	)
	if err == nil || !strings.Contains(err.Error(), "requires macOS") {
		t.Fatalf("error = %v, want macOS requirement", err)
	}
	if len(runner.calls) != 0 {
		t.Fatalf("runner calls = %v, want none", runner.calls)
	}
}

func TestVerifyDiskChecksDependenciesBeforeExecution(t *testing.T) {
	runner := &fakeRunner{}
	service := New(Options{
		GOOS:   "darwin",
		Runner: runner,
		LookPath: func(name string) (string, error) {
			if name == "f3write" {
				return "", errors.New("not found")
			}
			return "/usr/bin/" + name, nil
		},
	})

	err := service.VerifyDisk(
		context.Background(),
		"/Volumes/backup",
		&bytes.Buffer{},
		&bytes.Buffer{},
	)
	if err == nil || !strings.Contains(err.Error(), `required command "f3write"`) {
		t.Fatalf("error = %v, want missing f3write", err)
	}
	if len(runner.calls) != 0 {
		t.Fatalf("runner calls = %v, want none", runner.calls)
	}
}
