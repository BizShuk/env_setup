package cleanup

import (
	"context"
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"syscall"
	"time"

	modelcleanup "github.com/bizshuk/env_setup/model/cleanup"
)

// Inspect 建立不會在 apply 時重新擴大 selector scope 的 cleanup plan。
func (s *Service) Inspect(ctx context.Context) (*Plan, error) {
	plan := &Plan{
		actions: make(map[string]plannedAction, len(s.definitions)),
		runner:  s.runner,
	}
	seen := make(map[string]struct{}, len(s.definitions))

	for _, definition := range s.definitions {
		if err := ctx.Err(); err != nil {
			return nil, err
		}
		if definition.ID == "" {
			return nil, errors.New("cleanup item ID is empty")
		}
		if _, exists := seen[definition.ID]; exists {
			return nil, fmt.Errorf("duplicate cleanup item ID %q", definition.ID)
		}
		seen[definition.ID] = struct{}{}

		targets, discoverErr := discoverSelectors(ctx, definition.Selectors, time.Now(), s.runner)
		if discoverErr != nil {
			return nil, fmt.Errorf("inspect cleanup item %q: %w", definition.ID, discoverErr)
		}
		estimateTargets := targets
		if len(definition.EstimateSelectors) > 0 {
			estimateTargets, discoverErr = discoverSelectors(ctx, definition.EstimateSelectors, time.Now(), s.runner)
			if discoverErr != nil {
				return nil, fmt.Errorf("estimate cleanup item %q: %w", definition.ID, discoverErr)
			}
		}

		size, sizeKnown := targetsSize(estimateTargets)
		commandsAvailable := commandsExist(s.runner, definition.Commands)
		available := len(targets) > 0 || len(definition.Commands) > 0 && commandsAvailable
		itemSizeKnown := sizeKnown
		if len(definition.Commands) > 0 && len(estimateTargets) == 0 {
			itemSizeKnown = false
		}

		plan.items = append(plan.items, modelcleanup.Item{
			ID:          definition.ID,
			Description: definition.Description,
			SizeBytes:   size,
			SizeKnown:   itemSizeKnown,
			Available:   available,
		})
		plan.actions[definition.ID] = plannedAction{
			targets:      append([]string(nil), targets...),
			commands:     cloneCommands(definition.Commands),
			requiresRoot: definition.RequiresRoot,
		}
	}

	return plan, nil
}

func discoverSelectors(ctx context.Context, selectors []Selector, now time.Time, runner Runner) ([]string, error) {
	var targets []string
	for _, selector := range selectors {
		discovered, err := discoverSelector(selector, now)
		if err != nil {
			return nil, err
		}
		for _, path := range discovered {
			if selector.CurrentUserOnly && !ownedByCurrentUser(path) {
				continue
			}
			if selector.SkipInUse && pathInUse(ctx, runner, path) {
				continue
			}
			targets = append(targets, path)
		}
	}
	return uniquePaths(targets), nil
}

func ownedByCurrentUser(path string) bool {
	info, err := os.Lstat(path)
	if err != nil {
		return false
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	return ok && stat.Uid == uint32(os.Getuid())
}

func pathInUse(ctx context.Context, runner Runner, path string) bool {
	if _, err := runner.LookPath("lsof"); err != nil {
		return false
	}
	return runner.Run(ctx, "lsof", "+D", path) == nil
}

func discoverSelector(selector Selector, now time.Time) ([]string, error) {
	switch selector.Kind {
	case SELECTOR_PATH:
		if _, err := os.Lstat(selector.Path); errors.Is(err, os.ErrNotExist) {
			return nil, nil
		} else if err != nil {
			return nil, err
		}
		return []string{selector.Path}, nil
	case SELECTOR_CONTENTS:
		entries, err := os.ReadDir(selector.Path)
		if errors.Is(err, os.ErrNotExist) || errors.Is(err, fs.ErrPermission) {
			return nil, nil
		}
		if err != nil {
			return nil, err
		}
		paths := make([]string, 0, len(entries))
		for _, entry := range entries {
			paths = append(paths, filepath.Join(selector.Path, entry.Name()))
		}
		return paths, nil
	case SELECTOR_GLOB:
		paths, err := filepath.Glob(selector.Pattern)
		if err != nil || selector.OlderThanDays <= 0 {
			return paths, err
		}
		var oldPaths []string
		for _, path := range paths {
			info, statErr := os.Lstat(path)
			if statErr != nil {
				if errors.Is(statErr, os.ErrNotExist) {
					continue
				}
				return nil, statErr
			}
			if now.Sub(info.ModTime()) > olderThan(selector.OlderThanDays) {
				oldPaths = append(oldPaths, path)
			}
		}
		return oldPaths, nil
	case SELECTOR_OLDER_FILES:
		return findOlderFiles(selector, now)
	case SELECTOR_NAMED_DIRECTORIES:
		return findNamedDirectories(selector)
	default:
		return nil, fmt.Errorf("unknown selector kind %q", selector.Kind)
	}
}

func findOlderFiles(selector Selector, now time.Time) ([]string, error) {
	var paths []string
	err := filepath.WalkDir(selector.Path, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			if errors.Is(walkErr, fs.ErrPermission) {
				return nil
			}
			return walkErr
		}
		if path == selector.Path {
			return nil
		}
		if isExcluded(path, selector.Exclude) {
			if entry.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		if entry.IsDir() {
			return nil
		}
		info, err := entry.Info()
		if err != nil {
			return err
		}
		if now.Sub(info.ModTime()) > olderThan(selector.OlderThanDays) {
			paths = append(paths, path)
		}
		return nil
	})
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	return paths, err
}

func findNamedDirectories(selector Selector) ([]string, error) {
	var paths []string
	err := filepath.WalkDir(selector.Path, func(path string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			if errors.Is(walkErr, fs.ErrPermission) {
				return nil
			}
			return walkErr
		}
		if path == selector.Path {
			return nil
		}
		if isExcluded(path, selector.Exclude) {
			if entry.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		nameMatches, err := filepath.Match(selector.Name, entry.Name())
		if err != nil {
			return err
		}
		if entry.IsDir() && nameMatches {
			paths = append(paths, path)
			return filepath.SkipDir
		}
		return nil
	})
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	return paths, err
}

func targetsSize(targets []string) (int64, bool) {
	var total int64
	for _, target := range targets {
		size, err := pathSize(target)
		if err != nil {
			return total, false
		}
		total += size
	}
	return total, true
}

func pathSize(path string) (int64, error) {
	var total int64
	err := filepath.WalkDir(path, func(_ string, entry fs.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if entry.Type()&os.ModeSymlink != 0 {
			return nil
		}
		if entry.IsDir() {
			return nil
		}
		info, err := entry.Info()
		if err != nil {
			return err
		}
		total += info.Size()
		return nil
	})
	return total, err
}

func isExcluded(path string, excluded []string) bool {
	cleanPath := filepath.Clean(path)
	for _, root := range excluded {
		cleanRoot := filepath.Clean(root)
		if cleanPath == cleanRoot || strings.HasPrefix(cleanPath, cleanRoot+string(filepath.Separator)) {
			return true
		}
	}
	return false
}

func uniquePaths(paths []string) []string {
	sort.Strings(paths)
	result := paths[:0]
	for _, path := range paths {
		if len(result) == 0 || result[len(result)-1] != path {
			result = append(result, path)
		}
	}
	return result
}

func commandsExist(runner Runner, commands []Command) bool {
	if len(commands) == 0 {
		return false
	}
	for _, command := range commands {
		if _, err := runner.LookPath(command.Name); err != nil {
			return false
		}
	}
	return true
}

func cloneCommands(commands []Command) []Command {
	cloned := make([]Command, len(commands))
	for index, command := range commands {
		cloned[index] = Command{
			Name: command.Name,
			Args: append([]string(nil), command.Args...),
		}
	}
	return cloned
}
