// Package io probes block devices at the device level: transport, queue depth,
// write cache, mounts, and (optionally) latency-bound throughput.
package io

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

// Options configures platform boundaries used by Service.
type Options struct {
	GOOS     string
	Runner   Runner
	ReadFile func(string) ([]byte, error)
	ReadDir  func(string) ([]os.DirEntry, error)
	ReadLink func(string) (string, error)
	// EvalSymlinks resolves the sysfs device link, whose target is relative
	// to the *resolved* /sys/block/<dev> directory, not the alias.
	EvalSymlinks func(string) (string, error)
	HomeDir      func() (string, error)
}

// Service provides device-level I/O information and benchmarks.
type Service struct {
	goos         string
	runner       Runner
	readFile     func(string) ([]byte, error)
	readDir      func(string) ([]os.DirEntry, error)
	readLink     func(string) (string, error)
	evalSymlinks func(string) (string, error)
	homeDir      func() (string, error)
}

// New creates an I/O probe service.
func New(options Options) *Service {
	if options.GOOS == "" {
		options.GOOS = runtime.GOOS
	}
	if options.Runner == nil {
		options.Runner = NewCommandRunner()
	}
	if options.ReadFile == nil {
		options.ReadFile = os.ReadFile
	}
	if options.ReadDir == nil {
		options.ReadDir = os.ReadDir
	}
	if options.ReadLink == nil {
		options.ReadLink = os.Readlink
	}
	if options.EvalSymlinks == nil {
		options.EvalSymlinks = filepath.EvalSymlinks
	}
	if options.HomeDir == nil {
		options.HomeDir = os.UserHomeDir
	}
	return &Service{
		goos:         options.GOOS,
		runner:       options.Runner,
		readFile:     options.ReadFile,
		readDir:      options.ReadDir,
		readLink:     options.ReadLink,
		evalSymlinks: options.EvalSymlinks,
		homeDir:      options.HomeDir,
	}
}

// NewDefault creates a Service for the current host.
func NewDefault() *Service {
	return New(Options{})
}

// ProbeOptions selects what Probe renders.
type ProbeOptions struct {
	// Bench runs the write/read latency probe in Dir after the device table.
	Bench bool
	// Dir is the directory the benchmark writes its scratch file into.
	// Empty means the user's home directory.
	Dir string
	// SeqMiB is the sequential-write sample size in MiB.
	SeqMiB int
	// Ops is the operation count for the 4 KiB write and read samples.
	Ops int
}

// Probe renders the device table and, when requested, the benchmark.
func (s *Service) Probe(ctx context.Context, options ProbeOptions, out, errOut io.Writer) error {
	devices, err := s.Devices(ctx, errOut)
	if err != nil {
		return fmt.Errorf("probe devices: %w", err)
	}
	if err := renderDevices(out, devices); err != nil {
		return fmt.Errorf("render devices: %w", err)
	}
	if !options.Bench {
		return nil
	}
	if options.Dir == "" {
		options.Dir, err = s.homeDir()
		if err != nil {
			return fmt.Errorf("resolve home directory for benchmark: %w", err)
		}
	}
	if _, err := fmt.Fprintln(out); err != nil {
		return err
	}
	if err := s.Bench(ctx, options, out); err != nil {
		return fmt.Errorf("benchmark %s: %w", options.Dir, err)
	}
	return nil
}

func (s *Service) runOutput(ctx context.Context, in io.Reader, errOut io.Writer, name string, args ...string) ([]byte, error) {
	var output bytes.Buffer
	if err := s.runner.Run(ctx, in, &output, errOut, name, args...); err != nil {
		return nil, fmt.Errorf("run %s: %w", strings.Join(append([]string{name}, args...), " "), err)
	}
	return output.Bytes(), nil
}
