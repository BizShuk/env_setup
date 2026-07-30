package uninstall

import (
	"context"
	"io"

	rootsvc "github.com/bizshuk/env_setup/svc"
)

// Runner executes external macOS lifecycle commands.
type Runner interface {
	Run(context.Context, io.Reader, io.Writer, io.Writer, string, ...string) error
}

func newCommandRunner() Runner {
	return rootsvc.NewRunner()
}
