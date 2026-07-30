package system

import (
	"context"
	"fmt"
	"io"
	"strconv"
	"strings"
)

func (s *Service) showMemory(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "記憶體 (Memory)")

	var bytes int64
	if s.goos == "darwin" {
		output, err := s.runOutput(ctx, errOut, "sysctl", "-n", "hw.memsize")
		if err != nil {
			return err
		}
		bytes, err = strconv.ParseInt(output, 10, 64)
		if err != nil {
			return fmt.Errorf("parse memory size %q: %w", output, err)
		}
	} else {
		data, err := s.readFile("/proc/meminfo")
		if err != nil {
			return fmt.Errorf("read /proc/meminfo: %w", err)
		}
		for line := range strings.SplitSeq(string(data), "\n") {
			if !strings.HasPrefix(line, "MemTotal:") {
				continue
			}
			fields := strings.Fields(line)
			if len(fields) >= 2 {
				kilobytes, parseErr := strconv.ParseInt(fields[1], 10, 64)
				if parseErr != nil {
					return fmt.Errorf("parse MemTotal %q: %w", fields[1], parseErr)
				}
				bytes = kilobytes * 1024
			}
			break
		}
	}
	fmt.Fprintf(out, "- Total RAM: %d GB\n", bytes/(1024*1024*1024))
	return nil
}
