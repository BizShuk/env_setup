package system

import (
	"context"
	"io"

	process "github.com/bizshuk/env_setup/svc"
)

// Runner executes external platform commands for system probes.
type Runner interface {
	Run(context.Context, io.Reader, io.Writer, io.Writer, string, ...string) error
}

// NewCommandRunner creates a Runner backed by go-cmd.
func NewCommandRunner() Runner {
	return process.NewRunner()
}
