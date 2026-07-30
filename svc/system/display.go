package system

import (
	"context"
	"fmt"
	"io"
	"strings"
)

func (s *Service) showDisplay(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "顯示器 (Display)")

	var displays []string
	if s.goos == "darwin" {
		output, err := s.runOutput(ctx, errOut, "system_profiler", "SPDisplaysDataType")
		if err != nil {
			return err
		}
		displays = valuesAfterLabel(output, "Resolution:")
	} else {
		output, err := s.runOutput(ctx, errOut, "xrandr")
		if err != nil {
			output, err = s.runOutput(ctx, errOut, "xdpyinfo")
			if err != nil {
				return err
			}
			for line := range strings.SplitSeq(output, "\n") {
				fields := strings.Fields(line)
				if len(fields) >= 2 && fields[0] == "dimensions:" {
					displays = append(displays, fields[1])
				}
			}
		} else {
			for line := range strings.SplitSeq(output, "\n") {
				if strings.Contains(line, "*") {
					displays = append(displays, strings.Fields(line)[0])
					break
				}
			}
		}
	}
	for _, display := range displays {
		fmt.Fprintf(out, "- Display: %s\n", display)
	}
	return nil
}
