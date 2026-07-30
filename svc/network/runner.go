package network

import (
	"context"
	"fmt"
	"io"
	"os/exec"
)

// Runner executes external network tools.
type Runner interface {
	Run(context.Context, io.Reader, io.Writer, io.Writer, string, ...string) error
}

type osRunner struct{}

// NewOSRunner creates a Runner backed by os/exec.
func NewOSRunner() Runner {
	return osRunner{}
}

func (osRunner) Run(
	ctx context.Context,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
	name string,
	args ...string,
) error {
	command := exec.CommandContext(ctx, name, args...)
	command.Stdin = in
	command.Stdout = out
	command.Stderr = errOut
	if err := command.Run(); err != nil {
		return fmt.Errorf("%s: %w", name, err)
	}
	return nil
}
