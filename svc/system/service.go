package system

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"
)

// Options configures platform boundaries used by Service.
type Options struct {
	GOOS     string
	Runner   Runner
	Now      func() time.Time
	ReadFile func(string) ([]byte, error)
	CPUCount func() int
	LookPath func(string) (string, error)
}

// Service provides cross-platform system information.
type Service struct {
	goos     string
	runner   Runner
	now      func() time.Time
	readFile func(string) ([]byte, error)
	cpuCount func() int
	lookPath func(string) (string, error)
}

// New creates a system information service.
func New(options Options) *Service {
	if options.GOOS == "" {
		options.GOOS = runtime.GOOS
	}
	if options.Runner == nil {
		options.Runner = NewOSRunner()
	}
	if options.Now == nil {
		options.Now = time.Now
	}
	if options.ReadFile == nil {
		options.ReadFile = os.ReadFile
	}
	if options.CPUCount == nil {
		options.CPUCount = runtime.NumCPU
	}
	if options.LookPath == nil {
		options.LookPath = exec.LookPath
	}
	return &Service{
		goos:     options.GOOS,
		runner:   options.Runner,
		now:      options.Now,
		readFile: options.ReadFile,
		cpuCount: options.CPUCount,
		lookPath: options.LookPath,
	}
}

// NewDefault creates a Service for the current host.
func NewDefault() *Service {
	return New(Options{})
}

// Show renders one system information probe.
func (s *Service) Show(ctx context.Context, name string, out, errOut io.Writer) error {
	information, ok := findInformation(name)
	if !ok {
		return fmt.Errorf("unknown system information %q", name)
	}
	if err := information.show(s, ctx, out, errOut); err != nil {
		return fmt.Errorf("show %s information: %w", information.Name, err)
	}
	return nil
}

// ShowAll renders all system information probes in catalog order.
func (s *Service) ShowAll(ctx context.Context, out, errOut io.Writer) error {
	var showErrors []error
	for index, information := range informationCatalog {
		if index > 0 {
			if _, err := fmt.Fprintln(out); err != nil {
				showErrors = append(showErrors, fmt.Errorf("separate system information output: %w", err))
			}
		}
		if err := s.Show(ctx, information.Name, out, errOut); err != nil {
			showErrors = append(showErrors, err)
		}
	}
	return errors.Join(showErrors...)
}

func (s *Service) runOutput(ctx context.Context, errOut io.Writer, name string, args ...string) (string, error) {
	var output bytes.Buffer
	if err := s.runner.Run(ctx, nil, &output, errOut, name, args...); err != nil {
		return "", fmt.Errorf("run %s: %w", strings.Join(append([]string{name}, args...), " "), err)
	}
	return strings.TrimSpace(output.String()), nil
}
