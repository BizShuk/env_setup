package system

import (
	"context"
	"fmt"
	"io"
	"strings"
)

func (s *Service) showNetwork(ctx context.Context, out, errOut io.Writer) error {
	fmt.Fprintln(out, "正在偵測網絡介面... (Detecting network interfaces...)")
	fmt.Fprintln(out, "--------------------------------------------------")
	if s.goos == "darwin" {
		fmt.Fprintln(out, "作業系統 (OS): macOS (Darwin)")
		if err := s.showDarwinNetwork(ctx, out, errOut); err != nil {
			return err
		}
	} else {
		fmt.Fprintln(out, "作業系統 (OS): Linux")
		if err := s.showLinuxNetwork(ctx, out, errOut); err != nil {
			return err
		}
	}
	fmt.Fprintln(out, "--------------------------------------------------")
	return nil
}

func (s *Service) showDarwinNetwork(ctx context.Context, out, errOut io.Writer) error {
	output, err := s.runOutput(ctx, errOut, "networksetup", "-listallhardwareports")
	if err != nil {
		return err
	}
	var portName string
	for line := range strings.SplitSeq(output, "\n") {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "Hardware Port:") {
			portName = strings.TrimSpace(strings.TrimPrefix(line, "Hardware Port:"))
			continue
		}
		if !strings.HasPrefix(line, "Device:") {
			continue
		}
		device := strings.TrimSpace(strings.TrimPrefix(line, "Device:"))
		address, addressErr := s.runOutput(ctx, errOut, "ipconfig", "getifaddr", device)
		if addressErr != nil || address == "" {
			continue
		}
		fmt.Fprintf(out, "%s (%s): %s\n", networkType(portName, device), device, address)
	}
	return nil
}

func (s *Service) showLinuxNetwork(ctx context.Context, out, errOut io.Writer) error {
	output, err := s.runOutput(ctx, errOut, "ip", "-4", "-o", "addr", "show")
	if err != nil {
		return err
	}
	for line := range strings.SplitSeq(output, "\n") {
		fields := strings.Fields(line)
		if len(fields) < 4 || fields[1] == "lo" || fields[2] != "inet" {
			continue
		}
		address, _, _ := strings.Cut(fields[3], "/")
		fmt.Fprintf(out, "%s (%s): %s\n", networkType("", fields[1]), fields[1], address)
	}
	return nil
}

func networkType(portName, device string) string {
	lowerPort := strings.ToLower(portName)
	switch {
	case strings.Contains(lowerPort, "wi-fi"),
		strings.Contains(lowerPort, "airport"),
		strings.HasPrefix(device, "w"):
		return "WiFi"
	case strings.Contains(lowerPort, "ethernet"),
		strings.Contains(lowerPort, "lan"),
		strings.Contains(lowerPort, "thunderbolt"),
		strings.HasPrefix(device, "e"):
		return "區域網路 (LAN)"
	default:
		if portName != "" {
			return fmt.Sprintf("其他 (Other) [%s]", portName)
		}
		return "其他 (Other)"
	}
}
