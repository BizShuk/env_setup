package cmd

import (
	"bytes"
	"strings"
	"testing"

	cleanupsvc "github.com/bizshuk/env_setup/svc/cleanup"
	dumpsvc "github.com/bizshuk/env_setup/svc/dump"
	networksvc "github.com/bizshuk/env_setup/svc/network"
	systemsvc "github.com/bizshuk/env_setup/svc/system"
)

func TestRootContainsDomainSubcommands(t *testing.T) {
	cleanupService := cleanupsvc.New(nil, cleanupsvc.NewCommandRunner())
	dumpService := dumpsvc.New(dumpsvc.Options{})
	systemService := systemsvc.New(systemsvc.Options{})
	networkService := networksvc.New(networksvc.Options{})
	root := NewRootCommand(
		cleanupService,
		dumpService,
		systemService,
		networkService,
		strings.NewReader(""),
		&bytes.Buffer{},
		&bytes.Buffer{},
	)

	for _, name := range []string{"cleanup", "backup", "dump", "system", "network"} {
		command, _, err := root.Find([]string{name})
		if err != nil {
			t.Errorf("find %q: %v", name, err)
			continue
		}
		if command.Name() != name {
			t.Errorf("found command = %q, want %q", command.Name(), name)
		}
	}
}
