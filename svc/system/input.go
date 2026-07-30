package system

import (
	"context"
	"fmt"
	"io"
	"strings"
)

func (s *Service) showInput(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "輸入裝置 (Input Devices)")

	var devices []string
	if s.goos == "darwin" {
		output, err := s.runOutput(ctx, errOut, "system_profiler", "SPInputDataType")
		if err != nil {
			return err
		}
		devices = namesBeforeMarker(output, "Product ID:")
	} else {
		data, err := s.readFile("/proc/bus/input/devices")
		if err == nil {
			for line := range strings.SplitSeq(string(data), "\n") {
				if !strings.HasPrefix(line, "N: Name=") {
					continue
				}
				devices = append(devices, strings.Trim(strings.TrimPrefix(line, "N: Name="), "\""))
			}
		} else {
			output, commandErr := s.runOutput(ctx, errOut, "xinput", "list", "--short")
			if commandErr != nil {
				return commandErr
			}
			for line := range strings.SplitSeq(output, "\n") {
				if strings.Contains(line, "slave") {
					devices = append(devices, strings.TrimSpace(line))
				}
			}
		}
	}
	for _, device := range devices {
		fmt.Fprintf(out, "- %s\n", device)
	}
	return nil
}
