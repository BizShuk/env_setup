package system

import (
	"context"
	"fmt"
	"io"
	"strings"
)

func (s *Service) showGPU(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "顯示卡 (GPU)")

	var model string
	if s.goos == "darwin" {
		output, err := s.runOutput(ctx, errOut, "system_profiler", "SPDisplaysDataType")
		if err != nil {
			return err
		}
		model = firstNonEmpty(valuesAfterLabel(output, "Chipset Model:"))
	} else {
		output, err := s.runOutput(ctx, errOut, "lspci")
		if err != nil {
			return err
		}
		for line := range strings.SplitSeq(output, "\n") {
			if strings.Contains(strings.ToLower(line), "vga") {
				_, model, _ = strings.Cut(line, ": ")
				break
			}
		}
	}
	if model == "" {
		model = "unknown"
	}
	fmt.Fprintf(out, "- GPU Model: %s\n", model)
	return nil
}
