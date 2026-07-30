package cleanup

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// SelectorKind 指定如何從 filesystem 找出可清理的 exact targets。
type SelectorKind string

const (
	// SELECTOR_PATH 選取 Path 本身。
	SELECTOR_PATH SelectorKind = "path"
	// SELECTOR_CONTENTS 選取 Path 的所有直接 children，包含 dotfiles。
	SELECTOR_CONTENTS SelectorKind = "contents"
	// SELECTOR_GLOB 以 filepath.Glob 展開 Pattern。
	SELECTOR_GLOB SelectorKind = "glob"
	// SELECTOR_OLDER_FILES 遞迴選取 Path 下超過 OlderThanDays 的 files 與 symlinks。
	SELECTOR_OLDER_FILES SelectorKind = "older-files"
	// SELECTOR_NAMED_DIRECTORIES 遞迴選取 Path 下符合 Name 的 directories。
	SELECTOR_NAMED_DIRECTORIES SelectorKind = "named-directories"
)

// Selector 描述一組 filesystem targets。
type Selector struct {
	Kind            SelectorKind
	Path            string
	Pattern         string
	Name            string
	OlderThanDays   int
	Exclude         []string
	CurrentUserOnly bool
	SkipInUse       bool
}

// Command 描述不透過 shell interpolation 執行的 external command。
type Command struct {
	Name string
	Args []string
}

// Definition 是 cleanup catalog 中一個可獨立確認的 action。
type Definition struct {
	ID                string
	Description       string
	Selectors         []Selector
	EstimateSelectors []Selector
	Commands          []Command
	RequiresRoot      bool
}

// DefaultPaths 提供 default cleanup catalog 所需的 machine-specific roots。
type DefaultPaths struct {
	Home          string
	DarwinTemp    string
	DarwinCache   string
	SystemTemp    string
	RepositoryDir string
}

// NewDefault 建立目前使用者與 macOS machine paths 對應的 cleanup service。
func NewDefault() (*Service, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return nil, err
	}
	repositoryDir := filepath.Join(home, "projects", "env_setup")
	if cwd, cwdErr := os.Getwd(); cwdErr == nil {
		if _, statErr := os.Stat(filepath.Join(cwd, "scripts", "Brewfile")); statErr == nil {
			repositoryDir = cwd
		}
	}

	paths := DefaultPaths{
		Home:          home,
		DarwinTemp:    getconfPath("DARWIN_USER_TEMP_DIR"),
		DarwinCache:   getconfPath("DARWIN_USER_CACHE_DIR"),
		SystemTemp:    "/tmp",
		RepositoryDir: repositoryDir,
	}
	return New(DefaultDefinitions(paths), NewOSRunner()), nil
}

// DefaultDefinitions 合併三個 legacy mac_cleanup scripts 的 cleanup catalog。
func DefaultDefinitions(paths DefaultPaths) []Definition {
	home := paths.Home
	library := filepath.Join(home, "Library")
	lark := filepath.Join(library, "Application Support", "LarkInternational")
	larkAccount := filepath.Join(lark, "sdk_storage", "8f58e7b608ae3d17ece2f19469e37e1c")

	definitions := []Definition{
		{
			ID:          "chrome-code-sign-temp",
			Description: "清除 Chrome code-sign temporary clone",
			Selectors: selectorsWhen(paths.DarwinTemp != "", Selector{
				Kind:            SELECTOR_PATH,
				Path:            filepath.Join(filepath.Dir(paths.DarwinTemp), "X", "com.google.Chrome.code_sign_clone"),
				CurrentUserOnly: true,
				SkipInUse:       true,
			}),
		},
		{
			ID:          "chrome-temp",
			Description: "清除 Chrome 的 macOS temporary directories",
			Selectors: selectorsWhen(paths.DarwinTemp != "", Selector{
				Kind:            SELECTOR_GLOB,
				Pattern:         filepath.Join(paths.DarwinTemp, ".com.google.Chrome.*"),
				CurrentUserOnly: true,
				SkipInUse:       true,
			}),
		},
		{
			ID:          "clang-cache",
			Description: "清除 Clang compiler cache",
			Selectors: selectorsWhen(paths.DarwinCache != "", Selector{
				Kind:            SELECTOR_PATH,
				Path:            filepath.Join(paths.DarwinCache, "clang"),
				CurrentUserOnly: true,
				SkipInUse:       true,
			}),
		},
		{
			ID:          "blender-cache",
			Description: "清除 Blender cache",
			Selectors: selectorsWhen(paths.DarwinCache != "", Selector{
				Kind:            SELECTOR_PATH,
				Path:            filepath.Join(paths.DarwinCache, "org.blenderfoundation.blender"),
				CurrentUserOnly: true,
				SkipInUse:       true,
			}),
		},
		{
			ID:          "original-filings-temp",
			Description: "清除超過 1 天的 original-filings audit temporary directories",
			Selectors: []Selector{{
				Kind:            SELECTOR_GLOB,
				Pattern:         filepath.Join(paths.SystemTemp, ".original-filings-audit.*"),
				OlderThanDays:   1,
				CurrentUserOnly: true,
				SkipInUse:       true,
			}},
		},
		{
			ID:          "lark-logs",
			Description: "清除 Lark logs、network logs 與 crash dumps",
			Selectors: []Selector{
				{Kind: SELECTOR_GLOB, Pattern: filepath.Join(lark, "sdk_storage", "log", "xlog", "*.alaudalog")},
				{Kind: SELECTOR_GLOB, Pattern: filepath.Join(lark, "sdk_storage", "log", "native-pc-sdk", "*.log")},
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(lark, "sdk_storage", "log", "netlog")},
				{Kind: SELECTOR_GLOB, Pattern: filepath.Join(lark, "sdk_storage", "log", "monitor", "*.dmp")},
			},
		},
		{
			ID:          "lark-updates",
			Description: "清除 Lark update temporary data",
			Selectors: []Selector{
				{Kind: SELECTOR_PATH, Path: filepath.Join(lark, "update", "update_downloading")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(lark, "update", "update.noindex")},
			},
		},
		{
			ID:          "lark-search-index",
			Description: "清除 Lark search index 與 pipeline database",
			Selectors: []Selector{
				{Kind: SELECTOR_GLOB, Pattern: filepath.Join(larkAccount, "search_v2_*.db*")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(larkAccount, "pipeline.db")},
			},
		},
		{
			ID:          "lark-media-cache",
			Description: "清除 Lark avatars、images 與 stickers cache",
			Selectors: []Selector{
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(larkAccount, "resources", "avatars")},
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(larkAccount, "resources", "images")},
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(larkAccount, "resources", "stickers")},
			},
		},
		{
			ID:          "lark-gpu-cache",
			Description: "清除 Lark GPU、Shader 與 Code caches",
			Selectors: []Selector{
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(lark, "ShaderCache")},
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(lark, "GrShaderCache")},
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(lark, "GraphiteDawnCache")},
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(lark, "CodeCache")},
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(lark, "iron", "ShaderCache")},
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(lark, "iron", "GrShaderCache")},
				{Kind: SELECTOR_CONTENTS, Path: filepath.Join(lark, "iron", "GraphiteDawnCache")},
			},
		},
		{
			ID:          "chrome-cache",
			Description: "清除 Chrome Default profile Cache_Data",
			Selectors: []Selector{{
				Kind: SELECTOR_PATH,
				Path: filepath.Join(library, "Caches", "Google", "Chrome", "Default", "Cache", "Cache_Data"),
			}},
		},
		{
			ID:          "npx-cache",
			Description: "清除 npx temporary packages",
			Selectors:   []Selector{{Kind: SELECTOR_PATH, Path: filepath.Join(home, ".npm", "_npx")}},
		},
		{
			ID:                "npm-cache",
			Description:       "執行 npm cache clean --force",
			EstimateSelectors: []Selector{{Kind: SELECTOR_PATH, Path: filepath.Join(home, ".npm", "_cacache")}},
			Commands:          []Command{{Name: "npm", Args: []string{"cache", "clean", "--force"}}},
		},
		{
			ID:                "bun-cache",
			Description:       "清除 Bun package cache",
			EstimateSelectors: []Selector{{Kind: SELECTOR_PATH, Path: filepath.Join(home, ".bun", "install", "cache")}},
			Commands:          []Command{{Name: "bun", Args: []string{"pm", "cache", "rm"}}},
		},
		{
			ID:          "user-cache-old",
			Description: "清除 ~/.cache 中超過 30 天的 files 與 symlinks",
			Selectors:   []Selector{{Kind: SELECTOR_OLDER_FILES, Path: filepath.Join(home, ".cache"), OlderThanDays: 30}},
		},
		{
			ID:          "user-cache-all",
			Description: "清除 ~/.cache 的全部 contents",
			Selectors:   []Selector{{Kind: SELECTOR_CONTENTS, Path: filepath.Join(home, ".cache")}},
		},
		{
			ID:          "codex-generated-images",
			Description: "清除 Codex 超過 30 天的 generated images",
			Selectors:   []Selector{{Kind: SELECTOR_OLDER_FILES, Path: filepath.Join(home, ".codex", "generated_images"), OlderThanDays: 30}},
		},
		{
			ID:          "gemini-temp",
			Description: "清除 Gemini 超過 30 天的 temporary files",
			Selectors:   []Selector{{Kind: SELECTOR_OLDER_FILES, Path: filepath.Join(home, ".gemini", "tmp"), OlderThanDays: 30}},
		},
		{
			ID:          "codex-sessions",
			Description: "清除 Codex 超過 60 天的 session files",
			Selectors:   []Selector{{Kind: SELECTOR_OLDER_FILES, Path: filepath.Join(home, ".codex", "sessions"), OlderThanDays: 60}},
		},
		{
			ID:          "claude-sessions",
			Description: "清除 Claude 超過 60 天的 project session files",
			Selectors:   []Selector{{Kind: SELECTOR_OLDER_FILES, Path: filepath.Join(home, ".claude", "projects"), OlderThanDays: 60}},
		},
		{
			ID:          "node-modules",
			Description: "清除 ~/projects 下所有 node_modules directories",
			Selectors:   []Selector{{Kind: SELECTOR_NAMED_DIRECTORIES, Path: filepath.Join(home, "projects"), Name: "node_modules"}},
		},
		{
			ID:          "virtualenv-directories",
			Description: "清除 HOME 下名稱含 venv 的 virtual environment directories（保留 ~/.venv 等系統區）",
			Selectors: []Selector{{
				Kind: SELECTOR_NAMED_DIRECTORIES,
				Path: home,
				Name: "*venv*",
				Exclude: []string{
					filepath.Join(home, ".venv"),
					filepath.Join(home, "Library"),
					filepath.Join(home, ".Trash"),
					filepath.Join(home, ".cargo"),
					filepath.Join(home, ".rustup"),
					filepath.Join(home, ".npm"),
					filepath.Join(home, ".nvm"),
					filepath.Join(home, ".cache"),
					filepath.Join(home, ".local"),
				},
			}},
		},
		{
			ID:           "system-private-logs",
			Description:  "高風險：清除 /private/var/log 的 contents",
			Selectors:    []Selector{{Kind: SELECTOR_CONTENTS, Path: "/private/var/log"}},
			RequiresRoot: true,
		},
		{
			ID:           "system-private-tmp",
			Description:  "高風險：清除 /private/var/tmp 的 contents",
			Selectors:    []Selector{{Kind: SELECTOR_CONTENTS, Path: "/private/var/tmp"}},
			RequiresRoot: true,
		},
		{
			ID:           "system-library-logs",
			Description:  "清除 /Library/Logs 的 contents",
			Selectors:    []Selector{{Kind: SELECTOR_CONTENTS, Path: "/Library/Logs"}},
			RequiresRoot: true,
		},
		{
			ID:          "user-library-caches",
			Description: "清除 ~/Library/Caches 的全部 contents",
			Selectors:   []Selector{{Kind: SELECTOR_CONTENTS, Path: filepath.Join(library, "Caches")}},
		},
		{
			ID:           "system-library-caches",
			Description:  "高風險：清除 /Library/Caches 的 contents",
			Selectors:    []Selector{{Kind: SELECTOR_CONTENTS, Path: "/Library/Caches"}},
			RequiresRoot: true,
		},
		{
			ID:           "time-machine-snapshots",
			Description:  "刪除本機 Time Machine local snapshots",
			Commands:     []Command{{Name: "tmutil", Args: []string{"deletelocalsnapshots", "/"}}},
			RequiresRoot: true,
		},
		{
			ID:          "docker-unused-data",
			Description: "刪除未使用的 Docker containers、images 與 build cache",
			Commands: []Command{
				{Name: "docker", Args: []string{"container", "prune", "-f"}},
				{Name: "docker", Args: []string{"image", "prune", "-a", "-f"}},
				{Name: "docker", Args: []string{"builder", "prune", "-f"}},
			},
		},
		{
			ID:          "trash",
			Description: "永久清空使用者 Trash",
			Selectors:   []Selector{{Kind: SELECTOR_CONTENTS, Path: filepath.Join(home, ".Trash")}},
		},
		{
			ID:          "go-workspace-source",
			Description: "清除 legacy Go workspace source cache",
			Selectors:   []Selector{{Kind: SELECTOR_CONTENTS, Path: filepath.Join(home, "projects", ".local", "go", "src")}},
		},
		{
			ID:          "music-library",
			Description: "極高風險：刪除 ~/Music 的全部 contents（含 iMovie/iTunes media）",
			Selectors:   []Selector{{Kind: SELECTOR_CONTENTS, Path: filepath.Join(home, "Music")}},
		},
		{
			ID:          "whatsapp-media",
			Description: "高風險：刪除 WhatsApp local message media",
			Selectors: []Selector{{
				Kind: SELECTOR_CONTENTS,
				Path: filepath.Join(library, "Group Containers", "group.net.whatsapp.WhatsApp.shared", "Message", "Media"),
			}},
		},
		{
			ID:          "wechat-data",
			Description: "極高風險：刪除 WeChat chat history 與 local data",
			Selectors: []Selector{
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Containers", "com.tencent.xinWeChat", "Data")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Containers", "com.tencent.xinWeChat.WeChatMacShare", "Data")},
			},
		},
		{
			ID:          "podcast-streams",
			Description: "清除 Apple Podcasts streamed media cache",
			Selectors: []Selector{{
				Kind:    SELECTOR_GLOB,
				Pattern: filepath.Join(library, "Containers", "com.apple.podcasts", "Data", "tmp", "StreamedMedia", "*.mp3"),
			}},
		},
		{
			ID:          "ios-software-updates",
			Description: "清除已下載的 iPhone software updates",
			Selectors:   []Selector{{Kind: SELECTOR_CONTENTS, Path: filepath.Join(library, "iTunes", "iPhone Software Updates")}},
		},
		{
			ID:          "ios-device-backups",
			Description: "極高風險：刪除本機 iPhone/iPad device backups",
			Selectors:   []Selector{{Kind: SELECTOR_CONTENTS, Path: filepath.Join(library, "Application Support", "MobileSync", "Backup")}},
		},
		{
			ID:          "brew-bundle-unused",
			Description: "依 repository Brewfile 移除未宣告的 Homebrew packages",
			Commands: []Command{{
				Name: "brew",
				Args: []string{"bundle", "cleanup", "--file", filepath.Join(paths.RepositoryDir, "scripts", "Brewfile"), "--force"},
			}},
		},
		{
			ID:          "safari-profile",
			Description: "極高風險：重設 Safari preferences、cookies、saved state 與 bookmarks",
			Selectors: []Selector{
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Caches", "Apple - Safari - Safari Extensions Gallery")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Caches", "Metadata", "Safari")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Caches", "com.apple.Safari")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Caches", "com.apple.WebKit.PluginProcess")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Cookies", "Cookies.binarycookies")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Preferences", "Apple - Safari - Safari Extensions Gallery")},
				{Kind: SELECTOR_GLOB, Pattern: filepath.Join(library, "Preferences", "com.apple.Safari*.plist")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Preferences", "com.apple.WebFoundation.plist")},
				{Kind: SELECTOR_GLOB, Pattern: filepath.Join(library, "Preferences", "com.apple.WebKit.Plugin*.plist")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "PubSub", "Database")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Saved Application State", "com.apple.Safari.savedState")},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Safari", "Bookmarks.plist")},
			},
		},
		{
			ID:                "brew-cache",
			Description:       "執行 brew cleanup --prune=all",
			EstimateSelectors: []Selector{{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Caches", "Homebrew")}},
			Commands:          []Command{{Name: "brew", Args: []string{"cleanup", "--prune=all"}}},
		},
		{
			ID:          "go-build-cache",
			Description: "執行 go clean -cache",
			Commands:    []Command{{Name: "go", Args: []string{"clean", "-cache"}}},
		},
		{
			ID:                "pip-cache",
			Description:       "執行 pip cache purge",
			EstimateSelectors: []Selector{{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Caches", "pip")}},
			Commands:          []Command{{Name: "pip", Args: []string{"cache", "purge"}}},
		},
		{
			ID:          "uv-cache",
			Description: "清除 uv archive cache",
			Selectors:   []Selector{{Kind: SELECTOR_PATH, Path: filepath.Join(home, ".cache", "uv", "archive-v0")}},
		},
		{
			ID:           "java-runtime",
			Description:  "極高風險：移除所有 Java Virtual Machines、plugins 與 preferences",
			RequiresRoot: true,
			Selectors: []Selector{
				{Kind: SELECTOR_CONTENTS, Path: "/Library/Java/JavaVirtualMachines"},
				{Kind: SELECTOR_PATH, Path: "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin"},
				{Kind: SELECTOR_PATH, Path: "/Library/PreferencePanes/JavaControlPanel.prefPane"},
				{Kind: SELECTOR_PATH, Path: "/Library/Application Support/Oracle/Java"},
				{Kind: SELECTOR_PATH, Path: filepath.Join(library, "Application Support", "Oracle", "Java")},
			},
		},
	}
	return definitions
}

func selectorsWhen(condition bool, selector Selector) []Selector {
	if !condition {
		return nil
	}
	return []Selector{selector}
}

func getconfPath(name string) string {
	output, err := exec.Command("getconf", name).Output()
	if err != nil {
		return ""
	}
	return strings.TrimSuffix(strings.TrimSpace(string(output)), string(filepath.Separator))
}

func olderThan(days int) time.Duration {
	return time.Duration(days) * 24 * time.Hour
}
