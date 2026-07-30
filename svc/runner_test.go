package svc_test

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"testing"
	"time"

	"github.com/bizshuk/env_setup/svc"
)

const (
	helperMarker = "process-runner-helper"
	helperOutput = "output"
	helperExit   = "exit"
	helperSleep  = "sleep"
)

func TestRunnerForwardsStdoutAndStderrWithoutChangingBytes(t *testing.T) {
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	name, args := helperCommand(helperOutput)

	err := svc.NewRunner().Run(t.Context(), nil, &stdout, &stderr, name, args...)
	if err != nil {
		t.Fatal(err)
	}

	if got, want := stdout.String(), "stdout\x00without newline"; got != want {
		t.Fatalf("stdout = %q, want %q", got, want)
	}
	if got, want := stderr.String(), "stderr\r\n"; got != want {
		t.Fatalf("stderr = %q, want %q", got, want)
	}
}

func TestRunnerReturnsStructuredExitError(t *testing.T) {
	name, args := helperCommand(helperExit)

	err := svc.NewRunner().Run(t.Context(), nil, io.Discard, io.Discard, name, args...)
	var exitError *svc.ExitError
	if !errors.As(err, &exitError) {
		t.Fatalf("error = %v, want *process.ExitError", err)
	}
	if got, want := exitError.Code, 7; got != want {
		t.Fatalf("exit code = %d, want %d", got, want)
	}
}

func TestRunnerHonorsContextCancellation(t *testing.T) {
	name, args := helperCommand(helperSleep)
	ctx, cancel := context.WithTimeout(t.Context(), 100*time.Millisecond)
	defer cancel()
	startedAt := time.Now()

	err := svc.NewRunner().Run(ctx, nil, io.Discard, io.Discard, name, args...)

	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("error = %v, want context deadline exceeded", err)
	}
	if elapsed := time.Since(startedAt); elapsed > 3*time.Second {
		t.Fatalf("cancellation took %s, want at most 3s", elapsed)
	}
}

func TestProcessRunnerHelper(_ *testing.T) {
	mode := helperMode(os.Args)
	if mode == "" {
		return
	}

	switch mode {
	case helperOutput:
		if _, err := io.WriteString(os.Stdout, "stdout\x00without newline"); err != nil {
			os.Exit(70)
		}
		if _, err := io.WriteString(os.Stderr, "stderr\r\n"); err != nil {
			os.Exit(71)
		}
		os.Exit(0)
	case helperExit:
		os.Exit(7)
	case helperSleep:
		time.Sleep(time.Minute)
		os.Exit(0)
	default:
		os.Exit(72)
	}
}

func helperCommand(mode string) (string, []string) {
	return os.Args[0], []string{
		"-test.run=^TestProcessRunnerHelper$",
		"--",
		helperMarker,
		mode,
	}
}

func helperMode(args []string) string {
	for index, arg := range args {
		if arg == helperMarker && index+1 < len(args) {
			return args[index+1]
		}
	}
	return ""
}
