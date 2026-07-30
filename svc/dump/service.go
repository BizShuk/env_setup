// Package dump exports machine and IDE manifests into tracked repository files.
package dump

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
)

const repositoryModule = "github.com/bizshuk/env_setup"

// Options configures manifest paths and external command boundaries.
type Options struct {
	RepositoryDir string
	GOOS          string
	Runner        Runner
	LookPath      func(string) (string, error)
}

// Service exports machine and IDE manifests.
type Service struct {
	repositoryDir string
	goos          string
	runner        Runner
	lookPath      func(string) (string, error)
}

// New creates a manifest dump service.
func New(options Options) *Service {
	if options.RepositoryDir == "" {
		options.RepositoryDir = defaultRepositoryDir()
	}
	if options.GOOS == "" {
		options.GOOS = runtime.GOOS
	}
	if options.Runner == nil {
		options.Runner = NewCommandRunner()
	}
	if options.LookPath == nil {
		options.LookPath = exec.LookPath
	}
	return &Service{
		repositoryDir: options.RepositoryDir,
		goos:          options.GOOS,
		runner:        options.Runner,
		lookPath:      options.LookPath,
	}
}

// NewDefault creates a Service for the current repository and host.
func NewDefault() *Service {
	return New(Options{})
}

func defaultRepositoryDir() string {
	if repositoryDir := os.Getenv("REPO_DIR"); repositoryDir != "" {
		return repositoryDir
	}
	cwd, err := os.Getwd()
	if err != nil {
		return "."
	}
	for current := cwd; ; current = filepath.Dir(current) {
		if isRepositoryRoot(current) {
			return current
		}
		parent := filepath.Dir(current)
		if parent == current {
			return cwd
		}
	}
}

func (s *Service) validateRepository() error {
	if !isRepositoryRoot(s.repositoryDir) {
		return fmt.Errorf(
			"%s is not the %s repository root; run inside the repository or set REPO_DIR",
			s.repositoryDir,
			repositoryModule,
		)
	}
	return nil
}

func isRepositoryRoot(path string) bool {
	content, err := os.ReadFile(filepath.Join(path, "go.mod"))
	if err != nil {
		return false
	}
	for line := range strings.SplitSeq(string(content), "\n") {
		if strings.TrimSpace(line) == "module "+repositoryModule {
			return true
		}
	}
	return false
}

func (s *Service) requireCommand(name string) error {
	if _, err := s.lookPath(name); err != nil {
		return fmt.Errorf("required command %q is unavailable: %w", name, err)
	}
	return nil
}
