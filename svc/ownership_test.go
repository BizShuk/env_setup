package svc_test

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestDomainRunnersUseSharedServiceRunner(t *testing.T) {
	for _, domain := range []string{"cleanup", "dump", "install", "network", "system", "uninstall"} {
		path := filepath.Join(domain, "runner.go")
		content, err := os.ReadFile(path)
		if err != nil {
			t.Errorf("read %s runner: %v", domain, err)
			continue
		}
		source := string(content)
		if strings.Contains(source, "osRunner") || strings.Contains(source, "NewOSRunner") {
			t.Errorf("%s still defines the legacy OS runner", path)
		}
		if !strings.Contains(source, "github.com/bizshuk/env_setup/svc") {
			t.Errorf("%s does not use the shared service runner", path)
		}
	}
}
