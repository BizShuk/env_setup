package system

import (
	"context"
	"fmt"
	"io"
	"strings"
)

var diskVerifyCommands = []string{"diskutil", "f3write", "f3read"}

// VerifyDisk runs an F3 write/read verification against a macOS volume.
func (s *Service) VerifyDisk(
	ctx context.Context,
	volumePath string,
	out io.Writer,
	errOut io.Writer,
) error {
	if s.goos != "darwin" {
		return fmt.Errorf("disk verification requires macOS")
	}
	volumePath = strings.TrimSpace(volumePath)
	if volumePath == "" {
		return fmt.Errorf("volume path is required")
	}
	for _, name := range diskVerifyCommands {
		if _, err := s.lookPath(name); err != nil {
			return fmt.Errorf("required command %q is unavailable: %w", name, err)
		}
	}

	steps := []struct {
		name string
		args []string
	}{
		{name: "diskutil", args: []string{"info", volumePath}},
		{name: "f3write", args: []string{volumePath}},
		{name: "f3read", args: []string{volumePath}},
	}
	for _, step := range steps {
		if err := s.runner.Run(ctx, nil, out, errOut, step.name, step.args...); err != nil {
			return fmt.Errorf(
				"run %s: %w",
				strings.Join(append([]string{step.name}, step.args...), " "),
				err,
			)
		}
	}
	return nil
}
