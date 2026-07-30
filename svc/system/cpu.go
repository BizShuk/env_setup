package system

import (
	"context"
	"fmt"
	"io"
	"strconv"
	"strings"
)

func (s *Service) showCPU(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "處理器資訊 (CPU Information)")

	model := ""
	cores := s.cpuCount()
	if s.goos == "darwin" {
		var err error
		model, err = s.runOutput(ctx, errOut, "sysctl", "-n", "machdep.cpu.brand_string")
		if err != nil {
			return err
		}
		coreOutput, err := s.runOutput(ctx, errOut, "sysctl", "-n", "hw.ncpu")
		if err != nil {
			return err
		}
		if parsed, parseErr := strconv.Atoi(coreOutput); parseErr == nil {
			cores = parsed
		}
	} else {
		data, err := s.readFile("/proc/cpuinfo")
		if err != nil {
			return fmt.Errorf("read /proc/cpuinfo: %w", err)
		}
		for line := range strings.SplitSeq(string(data), "\n") {
			key, value, found := strings.Cut(line, ":")
			if found && (strings.TrimSpace(key) == "model name" || strings.TrimSpace(key) == "Model") {
				model = strings.TrimSpace(value)
				break
			}
		}
	}
	if model == "" {
		model = "unknown"
	}
	fmt.Fprintf(out, "- Model: %s\n", model)
	fmt.Fprintf(out, "- Cores: %d\n", cores)
	return nil
}
