package install

import (
	"context"
	"io"

	rootsvc "github.com/bizshuk/env_setup/svc"
)

// Runner executes external installer commands.
type Runner interface {
	Run(context.Context, io.Reader, io.Writer, io.Writer, string, ...string) error
}

func newCommandRunner() Runner {
	return rootsvc.NewRunner()
}
