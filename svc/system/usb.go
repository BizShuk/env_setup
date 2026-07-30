package system

import (
	"context"
	"fmt"
	"io"
	"strings"
)

func (s *Service) showUSB(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "USB 裝置 (USB Devices)")

	var devices []string
	if s.goos == "darwin" {
		output, err := s.runOutput(ctx, errOut, "system_profiler", "SPUSBDataType")
		if err != nil {
			return err
		}
		devices = namesBeforeMarker(output, "Product ID:")
	} else {
		output, err := s.runOutput(ctx, errOut, "lsusb")
		if err != nil {
			return err
		}
		for line := range strings.SplitSeq(output, "\n") {
			fields := strings.Fields(line)
			if len(fields) > 6 {
				devices = append(devices, strings.Join(fields[6:], " "))
			}
		}
	}
	for _, device := range devices {
		fmt.Fprintf(out, "- %s\n", device)
	}
	return nil
}
