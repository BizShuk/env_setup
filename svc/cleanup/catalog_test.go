package cleanup

import (
	"path/filepath"
	"testing"
)

func TestDefaultDefinitionsMergeAllThreeCleanupScripts(t *testing.T) {
	home := filepath.Join(string(filepath.Separator), "Users", "tester")
	definitions := DefaultDefinitions(DefaultPaths{
		Home:          home,
		DarwinTemp:    "/var/folders/test/T",
		DarwinCache:   "/var/folders/test/C",
		SystemTemp:    "/tmp",
		RepositoryDir: filepath.Join(home, "projects", "env_setup"),
	})

	byID := make(map[string]Definition, len(definitions))
	for _, definition := range definitions {
		if _, exists := byID[definition.ID]; exists {
			t.Fatalf("duplicate definition ID %q", definition.ID)
		}
		byID[definition.ID] = definition
	}

	expectedIDs := []string{
		"chrome-code-sign-temp",
		"chrome-temp",
		"clang-cache",
		"blender-cache",
		"original-filings-temp",
		"lark-logs",
		"lark-updates",
		"lark-search-index",
		"lark-media-cache",
		"lark-gpu-cache",
		"chrome-cache",
		"npx-cache",
		"npm-cache",
		"bun-cache",
		"user-cache-old",
		"user-cache-all",
		"codex-generated-images",
		"gemini-temp",
		"codex-sessions",
		"claude-sessions",
		"node-modules",
		"virtualenv-directories",
		"system-private-logs",
		"system-private-tmp",
		"system-library-logs",
		"user-library-caches",
		"system-library-caches",
		"time-machine-snapshots",
		"docker-unused-data",
		"trash",
		"go-workspace-source",
		"music-library",
		"whatsapp-media",
		"wechat-data",
		"podcast-streams",
		"ios-software-updates",
		"ios-device-backups",
		"brew-bundle-unused",
		"safari-profile",
		"brew-cache",
		"go-build-cache",
		"pip-cache",
		"uv-cache",
		"java-runtime",
	}
	for _, id := range expectedIDs {
		definition, exists := byID[id]
		if !exists {
			t.Errorf("missing cleanup definition %q", id)
			continue
		}
		if definition.Description == "" {
			t.Errorf("definition %q has no description", id)
		}
	}
	if len(byID) != len(expectedIDs) {
		t.Fatalf("definition count = %d, want %d", len(byID), len(expectedIDs))
	}

	npx := byID["npx-cache"]
	if got := npx.Selectors[0].Path; got != filepath.Join(home, ".npm", "_npx") {
		t.Fatalf("npx path = %q", got)
	}
	if !byID["system-private-logs"].RequiresRoot {
		t.Fatal("system-private-logs must require root")
	}
	if got := byID["brew-bundle-unused"].Commands[0].Args[3]; got != filepath.Join(home, "projects", "env_setup", "scripts", "Brewfile") {
		t.Fatalf("Brewfile path = %q", got)
	}
	if selector := byID["chrome-temp"].Selectors[0]; !selector.CurrentUserOnly || !selector.SkipInUse {
		t.Fatal("chrome-temp must preserve owner and in-use safety checks")
	}
}
