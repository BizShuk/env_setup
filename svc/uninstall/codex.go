package uninstall

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
)

const (
	scopeUser        = "user"
	scopeSystem      = "system"
	scopeUserLaunchd = "user-launchd"
)

// CodexOptions selects optional Codex uninstall scopes.
type CodexOptions struct {
	WithCodexBar bool
	PurgeSystem  bool
}

// Item is one immutable uninstall target shown before apply.
type Item struct {
	ID          string
	Scope       string
	Target      string
	Description string
	Available   bool
}

// CodexPlan preserves exact targets discovered before confirmation.
type CodexPlan struct {
	items      []Item
	actions    map[string]codexAction
	runner     Runner
	lookPath   func(string) (string, error)
	currentUID func() int
	removeAll  func(string) error
	quitOnce   sync.Once
	mu         sync.Mutex
}

type codexActionKind uint8

const (
	codexActionRemovePath codexActionKind = iota
	codexActionRemoveRootPath
	codexActionBootout
)

type codexAction struct {
	kind   codexActionKind
	target string
}

type codexSelector struct {
	id           string
	scope        string
	target       string
	description  string
	glob         bool
	requiresRoot bool
}

// InspectCodex discovers exact Codex artifacts without modifying machine state.
func (s *Service) InspectCodex(
	ctx context.Context,
	options CodexOptions,
) (*CodexPlan, error) {
	if s.goos != "darwin" {
		return nil, fmt.Errorf("Codex uninstall is supported only on macOS, not %s", s.goos)
	}
	if err := s.validateCodexRoots(); err != nil {
		return nil, err
	}

	plan := &CodexPlan{
		actions:    make(map[string]codexAction),
		runner:     s.runner,
		lookPath:   s.lookPath,
		currentUID: s.currentUID,
		removeAll:  s.removeAll,
	}
	labels, err := s.codexLaunchLabels(ctx)
	if err != nil {
		return nil, err
	}
	for index, label := range labels {
		id := indexedID("launch-agent", index, len(labels))
		plan.items = append(plan.items, Item{
			ID:          id,
			Scope:       scopeUserLaunchd,
			Target:      label,
			Description: "Unload Codex user launchd service",
			Available:   true,
		})
		plan.actions[id] = codexAction{
			kind:   codexActionBootout,
			target: label,
		}
	}

	seenTargets := make(map[string]struct{})
	for _, selector := range s.codexSelectors(options) {
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		targets, discoverErr := discoverCodexTargets(selector)
		if discoverErr != nil {
			return nil, fmt.Errorf("discover %s: %w", selector.description, discoverErr)
		}
		if len(targets) == 0 {
			plan.items = append(plan.items, Item{
				ID:          selector.id,
				Scope:       selector.scope,
				Target:      selector.target,
				Description: selector.description,
				Available:   false,
			})
			continue
		}

		for index, target := range targets {
			if _, exists := seenTargets[target]; exists {
				continue
			}
			seenTargets[target] = struct{}{}
			id := indexedID(selector.id, index, len(targets))
			kind := codexActionRemovePath
			if selector.requiresRoot {
				kind = codexActionRemoveRootPath
			}
			plan.items = append(plan.items, Item{
				ID:          id,
				Scope:       selector.scope,
				Target:      target,
				Description: selector.description,
				Available:   true,
			})
			plan.actions[id] = codexAction{
				kind:   kind,
				target: target,
			}
		}
	}
	return plan, nil
}

// Items returns a copy of the immutable uninstall preview.
func (p *CodexPlan) Items() []Item {
	return append([]Item(nil), p.items...)
}

// Apply executes one exact target previously returned by Items.
func (p *CodexPlan) Apply(
	ctx context.Context,
	id string,
	out io.Writer,
	errOut io.Writer,
) error {
	p.mu.Lock()
	defer p.mu.Unlock()

	action, exists := p.actions[id]
	if !exists {
		return fmt.Errorf("unknown or unavailable Codex uninstall item %q", id)
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	p.quitCodexBestEffort(ctx)

	switch action.kind {
	case codexActionRemovePath:
		if err := p.removeAll(action.target); err != nil {
			return fmt.Errorf("remove %s: %w", action.target, err)
		}
	case codexActionRemoveRootPath:
		if err := p.runner.Run(
			ctx,
			nil,
			out,
			errOut,
			"sudo",
			"rm",
			"-rf",
			"--",
			action.target,
		); err != nil {
			return fmt.Errorf("remove system path %s: %w", action.target, err)
		}
	case codexActionBootout:
		domainTarget := fmt.Sprintf("gui/%d/%s", p.currentUID(), action.target)
		if err := p.runner.Run(
			ctx,
			nil,
			out,
			errOut,
			"launchctl",
			"bootout",
			domainTarget,
		); err != nil {
			return fmt.Errorf("bootout launchd label %s: %w", action.target, err)
		}
	default:
		return fmt.Errorf("unknown Codex uninstall action for %q", id)
	}
	return nil
}

func (p *CodexPlan) quitCodexBestEffort(ctx context.Context) {
	p.quitOnce.Do(func() {
		if _, err := p.lookPath("osascript"); err != nil {
			return
		}
		_ = p.runner.Run(
			ctx,
			nil,
			io.Discard,
			io.Discard,
			"osascript",
			"-e",
			`quit app "Codex"`,
		)
	})
}

func (s *Service) validateCodexRoots() error {
	for name, path := range map[string]string{
		"home":           s.homeDir,
		"applications":   s.applicationsDir,
		"system library": s.systemLibrary,
		"etc":            s.etcDir,
	} {
		if path == "" {
			return fmt.Errorf("%s directory is empty", name)
		}
		if !filepath.IsAbs(path) {
			return fmt.Errorf("%s directory must be absolute: %s", name, path)
		}
	}
	return nil
}

func (s *Service) codexLaunchLabels(ctx context.Context) ([]string, error) {
	if _, err := s.lookPath("launchctl"); err != nil {
		return nil, nil
	}
	var output bytes.Buffer
	if err := s.runner.Run(
		ctx,
		nil,
		&output,
		io.Discard,
		"launchctl",
		"list",
	); err != nil {
		if ctxErr := ctx.Err(); ctxErr != nil {
			return nil, ctxErr
		}
		return nil, nil
	}

	labels := make(map[string]struct{})
	for line := range strings.SplitSeq(output.String(), "\n") {
		fields := strings.Fields(line)
		if len(fields) < 3 || !strings.Contains(fields[2], "com.openai.codex") {
			continue
		}
		labels[fields[2]] = struct{}{}
	}
	result := make([]string, 0, len(labels))
	for label := range labels {
		result = append(result, label)
	}
	sort.Strings(result)
	return result, nil
}

func (s *Service) codexSelectors(options CodexOptions) []codexSelector {
	library := filepath.Join(s.homeDir, "Library")
	selectors := []codexSelector{
		{
			id:          "codex-app",
			scope:       scopeUser,
			target:      filepath.Join(s.applicationsDir, "Codex.app"),
			description: "Remove Codex desktop app",
		},
		{
			id:          "codex-cli",
			scope:       scopeUser,
			target:      filepath.Join(s.homeDir, ".local", "bin", "codex"),
			description: "Remove per-user Codex CLI",
		},
		{
			id:          "codex-home",
			scope:       scopeUser,
			target:      filepath.Join(s.homeDir, ".codex"),
			description: "Remove Codex configuration and per-user data",
		},
		{
			id:          "application-support",
			scope:       scopeUser,
			target:      filepath.Join(library, "Application Support", "Codex"),
			description: "Remove Codex Application Support data",
		},
		{
			id:          "cache",
			scope:       scopeUser,
			target:      filepath.Join(library, "Caches", "Codex"),
			description: "Remove Codex cache",
		},
		{
			id:          "saved-state",
			scope:       scopeUser,
			target:      filepath.Join(library, "Saved Application State", "com.openai.codex.savedState"),
			description: "Remove Codex saved application state",
		},
		{
			id:          "logs",
			scope:       scopeUser,
			target:      filepath.Join(library, "Logs", "Codex"),
			description: "Remove Codex logs",
		},
		{
			id:          "bundle-cache",
			scope:       scopeUser,
			target:      filepath.Join(library, "Caches", "com.openai.codex*"),
			description: "Remove Codex bundle caches",
			glob:        true,
		},
		{
			id:          "bundle-saved-state",
			scope:       scopeUser,
			target:      filepath.Join(library, "Saved Application State", "com.openai.codex*"),
			description: "Remove Codex bundle saved states",
			glob:        true,
		},
		{
			id:          "container",
			scope:       scopeUser,
			target:      filepath.Join(library, "Containers", "com.openai.codex*"),
			description: "Remove Codex sandbox containers",
			glob:        true,
		},
		{
			id:          "preference",
			scope:       scopeUser,
			target:      filepath.Join(library, "Preferences", "com.openai.codex*"),
			description: "Remove Codex preferences",
			glob:        true,
		},
		{
			id:          "launch-agent-file",
			scope:       scopeUser,
			target:      filepath.Join(library, "LaunchAgents", "com.openai.codex*"),
			description: "Remove Codex user LaunchAgent files",
			glob:        true,
		},
	}
	if options.WithCodexBar {
		selectors = append(selectors, codexSelector{
			id:          "codexbar-app",
			scope:       scopeUser,
			target:      filepath.Join(s.applicationsDir, "CodexBar.app"),
			description: "Remove CodexBar desktop app",
		})
	}
	if options.PurgeSystem {
		selectors = append(
			selectors,
			codexSelector{
				id:           "system-launch-agent",
				scope:        scopeSystem,
				target:       filepath.Join(s.systemLibrary, "LaunchAgents", "com.openai.codex*"),
				description:  "Remove system Codex LaunchAgent files",
				glob:         true,
				requiresRoot: true,
			},
			codexSelector{
				id:           "system-launch-daemon",
				scope:        scopeSystem,
				target:       filepath.Join(s.systemLibrary, "LaunchDaemons", "com.openai.codex*"),
				description:  "Remove system Codex LaunchDaemon files",
				glob:         true,
				requiresRoot: true,
			},
			codexSelector{
				id:           "system-etc",
				scope:        scopeSystem,
				target:       filepath.Join(s.etcDir, "codex"),
				description:  "Remove system Codex configuration",
				requiresRoot: true,
			},
		)
	}
	return selectors
}

func discoverCodexTargets(selector codexSelector) ([]string, error) {
	if selector.glob {
		return filepath.Glob(selector.target)
	}
	if _, err := os.Lstat(selector.target); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return nil, nil
		}
		return nil, err
	}
	return []string{selector.target}, nil
}

func indexedID(base string, index, count int) string {
	if count == 1 {
		return base
	}
	return fmt.Sprintf("%s-%d", base, index+1)
}
