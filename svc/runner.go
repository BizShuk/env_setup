// Package svc provides shared service adapters.
package svc

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os/exec"
	"time"

	gocmd "github.com/go-cmd/cmd"
)

// ExitError reports a command that completed with a non-zero exit code.
type ExitError struct {
	Name string
	Code int
}

// Error implements error.
func (e *ExitError) Error() string {
	return fmt.Sprintf("%s exited with code %d", e.Name, e.Code)
}

// Runner executes commands with go-cmd while preserving byte-oriented I/O.
type Runner struct{}

// NewRunner creates a go-cmd-backed Runner.
func NewRunner() Runner {
	return Runner{}
}

// Run executes one command and waits for completion or context cancellation.
func (Runner) Run(
	ctx context.Context,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
	name string,
	args ...string,
) error {
	command := gocmd.NewCmdOptions(
		gocmd.Options{
			BeforeExec: []func(*exec.Cmd){
				func(executable *exec.Cmd) {
					executable.Stdout = out
					executable.Stderr = errOut
				},
			},
		},
		name,
		args...,
	)
	statusChannel := command.StartWithStdin(in)

	select {
	case status := <-statusChannel:
		return statusError(name, status)
	case <-ctx.Done():
		select {
		case status := <-statusChannel:
			return statusError(name, status)
		default:
		}
		stopErr := stopWhenStarted(command, statusChannel)
		contextErr := fmt.Errorf("%s: %w", name, context.Cause(ctx))
		if stopErr != nil {
			return errors.Join(contextErr, fmt.Errorf("stop %s: %w", name, stopErr))
		}
		return contextErr
	}
}

func stopWhenStarted(command *gocmd.Cmd, statusChannel <-chan gocmd.Status) error {
	ticker := time.NewTicker(time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-statusChannel:
			return nil
		case <-ticker.C:
			if command.Status().PID == 0 {
				continue
			}
			stopErr := command.Stop()
			<-statusChannel
			return stopErr
		}
	}
}

func statusError(name string, status gocmd.Status) error {
	if status.Error != nil {
		return fmt.Errorf("%s: %w", name, status.Error)
	}
	if status.Exit != 0 {
		return &ExitError{Name: name, Code: status.Exit}
	}
	if !status.Complete {
		return fmt.Errorf("%s did not complete", name)
	}
	return nil
}
