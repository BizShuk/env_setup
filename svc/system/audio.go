package system

import (
	"context"
	"fmt"
	"io"
	"strings"
)

func (s *Service) showAudio(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "音訊裝置 (Audio Devices)")

	var devices []string
	if s.goos == "darwin" {
		output, err := s.runOutput(ctx, errOut, "system_profiler", "SPAudioDataType")
		if err != nil {
			return err
		}
		devices = namesBeforeMarker(output, "Default Output Device: Yes")
	} else {
		output, err := s.runOutput(ctx, errOut, "aplay", "-l")
		if err == nil {
			for line := range strings.SplitSeq(output, "\n") {
				if !strings.Contains(line, "card ") {
					continue
				}
				_, description, found := strings.Cut(line, ":")
				if found {
					description, _, _ = strings.Cut(strings.TrimSpace(description), "[")
					devices = append(devices, strings.TrimSpace(description))
				}
			}
		} else {
			output, err = s.runOutput(ctx, errOut, "pactl", "list", "sinks")
			if err != nil {
				return err
			}
			devices = valuesAfterLabel(output, "Description:")
		}
	}
	for _, device := range devices {
		fmt.Fprintf(out, "- Output: %s\n", device)
	}
	return nil
}
