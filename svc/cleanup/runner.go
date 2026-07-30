package cleanup

import (
	"context"
	"fmt"
	"os/exec"
)

// Runner 執行 catalog 中不適合直接以 filesystem API 處理的 commands。
type Runner interface {
	LookPath(file string) (string, error)
	Run(ctx context.Context, name string, args ...string) error
}

type osRunner struct{}

// NewOSRunner 建立使用 os/exec 的 command runner。
func NewOSRunner() Runner {
	return osRunner{}
}

func (osRunner) LookPath(file string) (string, error) {
	return exec.LookPath(file)
}

func (osRunner) Run(ctx context.Context, name string, args ...string) error {
	command := exec.CommandContext(ctx, name, args...)
	if output, err := command.CombinedOutput(); err != nil {
		return fmt.Errorf("%s: %w: %s", name, err, output)
	}
	return nil
}
