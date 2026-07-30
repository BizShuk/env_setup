// Package uninstall removes explicitly selected local tool artifacts.
package uninstall

import (
	"os"
	"os/exec"
	"runtime"
)

// Options configures filesystem and process boundaries.
type Options struct {
	HomeDir         string
	ApplicationsDir string
	SystemLibrary   string
	EtcDir          string
	GOOS            string
	Runner          Runner
	LookPath        func(string) (string, error)
	CurrentUID      func() int
	RemoveAll       func(string) error
}

// Service discovers uninstall targets and creates immutable apply plans.
type Service struct {
	homeDir         string
	applicationsDir string
	systemLibrary   string
	etcDir          string
	goos            string
	runner          Runner
	lookPath        func(string) (string, error)
	currentUID      func() int
	removeAll       func(string) error
}

// New creates an uninstall service with injectable machine boundaries.
func New(options Options) *Service {
	if options.ApplicationsDir == "" {
		options.ApplicationsDir = "/Applications"
	}
	if options.SystemLibrary == "" {
		options.SystemLibrary = "/Library"
	}
	if options.EtcDir == "" {
		options.EtcDir = "/etc"
	}
	if options.GOOS == "" {
		options.GOOS = runtime.GOOS
	}
	if options.Runner == nil {
		options.Runner = newCommandRunner()
	}
	if options.LookPath == nil {
		options.LookPath = exec.LookPath
	}
	if options.CurrentUID == nil {
		options.CurrentUID = os.Getuid
	}
	if options.RemoveAll == nil {
		options.RemoveAll = os.RemoveAll
	}
	return &Service{
		homeDir:         options.HomeDir,
		applicationsDir: options.ApplicationsDir,
		systemLibrary:   options.SystemLibrary,
		etcDir:          options.EtcDir,
		goos:            options.GOOS,
		runner:          options.Runner,
		lookPath:        options.LookPath,
		currentUID:      options.CurrentUID,
		removeAll:       options.RemoveAll,
	}
}

// NewDefault creates an uninstall service for the current macOS user.
func NewDefault() (*Service, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}
	return New(Options{HomeDir: homeDir}), nil
}
