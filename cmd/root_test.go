package cmd

import (
	"bytes"
	"strings"
	"testing"

	cleanupsvc "github.com/bizshuk/env_setup/svc/cleanup"
	dumpsvc "github.com/bizshuk/env_setup/svc/dump"
	installsvc "github.com/bizshuk/env_setup/svc/install"
	iosvc "github.com/bizshuk/env_setup/svc/io"
	networksvc "github.com/bizshuk/env_setup/svc/network"
	systemsvc "github.com/bizshuk/env_setup/svc/system"
	uninstallsvc "github.com/bizshuk/env_setup/svc/uninstall"
)

func TestRootContainsDomainSubcommands(t *testing.T) {
	cleanupService := cleanupsvc.New(nil, cleanupsvc.NewCommandRunner())
	dumpService := dumpsvc.New(dumpsvc.Options{})
	installService := installsvc.New(installsvc.Options{})
	uninstallService := uninstallsvc.New(uninstallsvc.Options{})
	systemService := systemsvc.New(systemsvc.Options{})
	networkService := networksvc.New(networksvc.Options{})
	ioService := iosvc.New(iosvc.Options{})
	root := NewRootCommand(
		cleanupService,
		dumpService,
		installService,
		uninstallService,
		systemService,
		networkService,
		ioService,
		strings.NewReader(""),
		&bytes.Buffer{},
		&bytes.Buffer{},
	)

	for _, name := range []string{
		"cleanup",
		"backup",
		"dump",
		"install",
		"uninstall",
		"system",
		"network",
		"io",
	} {
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
