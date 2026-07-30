package system

import (
	"context"
	"fmt"
	"io"
	"strings"
)

func (s *Service) showOS(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "系統概況 (System Overview)")

	var description string
	if s.goos == "darwin" {
		name, err := s.runOutput(ctx, errOut, "sw_vers", "-productName")
		if err != nil {
			return err
		}
		version, err := s.runOutput(ctx, errOut, "sw_vers", "-productVersion")
		if err != nil {
			return err
		}
		architecture, err := s.runOutput(ctx, errOut, "uname", "-m")
		if err != nil {
			return err
		}
		description = fmt.Sprintf("%s %s (%s)", name, version, architecture)
	} else {
		description = s.linuxOSDescription(ctx, errOut)
	}

	fmt.Fprintf(out, "- OS: %s\n", description)
	fmt.Fprintf(out, "- Date: %s\n", s.now().Format("2006-01-02 15:04:05 -07:00"))
	return nil
}

func (s *Service) linuxOSDescription(ctx context.Context, errOut io.Writer) string {
	data, err := s.readFile("/etc/os-release")
	if err == nil {
		for line := range strings.SplitSeq(string(data), "\n") {
			if strings.HasPrefix(line, "PRETTY_NAME=") {
				return strings.Trim(strings.TrimPrefix(line, "PRETTY_NAME="), "\"")
			}
		}
	}
	description, commandErr := s.runOutput(ctx, errOut, "uname", "-sr")
	if commandErr != nil {
		return "Linux"
	}
	return description
}
