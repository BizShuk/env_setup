package svc

import (
	"os"
	"path/filepath"
)

// AntigravityExtensionsDirEnv overrides the detected Antigravity extensions directory.
const AntigravityExtensionsDirEnv = "AGY_EXTENSIONS_DIR"

// AntigravityExtensionsDir reports the extensions directory agy-ide must target on this
// machine, or "" to keep the CLI default. A host that only serves Remote-SSH windows
// keeps its extensions under ~/.antigravity-ide-server/extensions; the desktop CLI writes
// to ~/.antigravity-ide/extensions instead, which such a host never reads.
func AntigravityExtensionsDir() string {
	if override := os.Getenv(AntigravityExtensionsDirEnv); override != "" {
		return override
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	if isDirectory(filepath.Join(home, ".antigravity-ide", "User")) {
		return ""
	}
	if !isDirectory(filepath.Join(home, ".antigravity-ide-server", "data", "User")) {
		return ""
	}
	return filepath.Join(home, ".antigravity-ide-server", "extensions")
}

func isDirectory(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}
