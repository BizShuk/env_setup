package cleanup

import (
	"bytes"
	"context"
	"fmt"
	"os/exec"
	"strings"

	process "github.com/bizshuk/env_setup/svc"
)

// Runner 執行 catalog 中不適合直接以 filesystem API 處理的 commands。
type Runner interface {
	LookPath(file string) (string, error)
	Run(ctx context.Context, name string, args ...string) error
}

type commandRunner struct {
	processRunner process.Runner
}

// NewCommandRunner 建立使用 go-cmd 的 command runner。
func NewCommandRunner() Runner {
	return commandRunner{processRunner: process.NewRunner()}
}

func (commandRunner) LookPath(file string) (string, error) {
	return exec.LookPath(file)
}

func (r commandRunner) Run(ctx context.Context, name string, args ...string) error {
	var output bytes.Buffer
	if err := r.processRunner.Run(ctx, nil, &output, &output, name, args...); err != nil {
		details := strings.TrimSpace(output.String())
		if details == "" {
			return err
		}
		return fmt.Errorf("%w: %s", err, details)
	}
	return nil
}
