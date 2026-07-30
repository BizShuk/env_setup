// Package network provides target discovery and private-route topology scans.
package network

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net"
	"net/netip"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

// Options configures host boundaries used by Service.
type Options struct {
	GOOS           string
	Runner         Runner
	LookPath       func(string) (string, error)
	Hostname       func() (string, error)
	LocalAddresses func() ([]netip.Addr, error)
}

// Service scans target networks and private route topology.
type Service struct {
	goos           string
	runner         Runner
	lookPath       func(string) (string, error)
	hostname       func() (string, error)
	localAddresses func() ([]netip.Addr, error)
}

// New creates a network scan service.
func New(options Options) *Service {
	if options.GOOS == "" {
		options.GOOS = runtime.GOOS
	}
	if options.Runner == nil {
		options.Runner = NewOSRunner()
	}
	if options.LookPath == nil {
		options.LookPath = exec.LookPath
	}
	if options.Hostname == nil {
		options.Hostname = defaultHostname
	}
	if options.LocalAddresses == nil {
		options.LocalAddresses = localIPv4Addresses
	}
	return &Service{
		goos:           options.GOOS,
		runner:         options.Runner,
		lookPath:       options.LookPath,
		hostname:       options.Hostname,
		localAddresses: options.LocalAddresses,
	}
}

// NewDefault creates a Service for the current host.
func NewDefault() *Service {
	return New(Options{})
}

func (s *Service) runOutput(
	ctx context.Context,
	errOut io.Writer,
	name string,
	args ...string,
) (string, error) {
	var output bytes.Buffer
	if err := s.runner.Run(ctx, nil, &output, errOut, name, args...); err != nil {
		command := strings.Join(append([]string{name}, args...), " ")
		return "", fmt.Errorf("run %s: %w", command, err)
	}
	return output.String(), nil
}

func defaultHostname() (string, error) {
	name, err := os.Hostname()
	if err != nil {
		return "", fmt.Errorf("read hostname: %w", err)
	}
	return name, nil
}

func localIPv4Addresses() ([]netip.Addr, error) {
	interfaces, err := net.Interfaces()
	if err != nil {
		return nil, fmt.Errorf("list network interfaces: %w", err)
	}

	var addresses []netip.Addr
	for _, networkInterface := range interfaces {
		interfaceAddresses, err := networkInterface.Addrs()
		if err != nil {
			continue
		}
		for _, interfaceAddress := range interfaceAddresses {
			prefix, err := netip.ParsePrefix(interfaceAddress.String())
			if err != nil {
				continue
			}
			address := prefix.Addr()
			if address.Is4() && !address.IsLoopback() {
				addresses = append(addresses, address)
			}
		}
	}
	return addresses, nil
}
