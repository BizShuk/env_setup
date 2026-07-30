package system

import (
	"context"
	"fmt"
	"io"
	"strings"
)

func (s *Service) showDisk(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "磁碟儲存 (Disk Storage)")
	output, err := s.runOutput(ctx, errOut, "df", "-h", "/")
	if err != nil {
		return err
	}
	lines := strings.Split(output, "\n")
	if len(lines) < 2 {
		return fmt.Errorf("parse df output: expected header and root filesystem")
	}
	fields := strings.Fields(lines[len(lines)-1])
	if len(fields) < 5 {
		return fmt.Errorf("parse df output line %q", lines[len(lines)-1])
	}
	fmt.Fprintf(
		out,
		"- Root Partition: %s (Used: %s, Free: %s, Usage: %s)\n",
		fields[1],
		fields[2],
		fields[3],
		fields[4],
	)
	return nil
}
