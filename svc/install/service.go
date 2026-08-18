// Package install restores tracked development manifests into local tools.
package install

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	rootsvc "github.com/bizshuk/env_setup/svc"
)

const repositoryModule = "github.com/bizshuk/env_setup"

// Options configures manifest paths and external command boundaries.
type Options struct {
	RepositoryDir string
	ExtensionsDir string
	Runner        Runner
	LookPath      func(string) (string, error)
}

// Service installs development-tool state from tracked manifests.
type Service struct {
	repositoryDir string
	extensionsDir string
	runner        Runner
	lookPath      func(string) (string, error)
}

// New creates a manifest install service.
func New(options Options) *Service {
	if options.RepositoryDir == "" {
		options.RepositoryDir = defaultRepositoryDir()
	}
	if options.Runner == nil {
		options.Runner = newCommandRunner()
	}
	if options.LookPath == nil {
		options.LookPath = exec.LookPath
	}
	return &Service{
		repositoryDir: options.RepositoryDir,
		extensionsDir: options.ExtensionsDir,
		runner:        options.Runner,
		lookPath:      options.LookPath,
	}
}

// NewDefault creates a Service for the current repository and Antigravity install.
func NewDefault() *Service {
	return New(Options{ExtensionsDir: rootsvc.AntigravityExtensionsDir()})
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
