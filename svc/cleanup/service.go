package cleanup

import (
	"context"
	"fmt"
	"os"
	"sync"

	modelcleanup "github.com/bizshuk/env_setup/model/cleanup"
)

// Service discovers cleanup items from a fixed catalog.
type Service struct {
	definitions []Definition
	runner      Runner
}

// Plan 保存 preview 時取得的 exact targets，供 confirmation 後套用。
type Plan struct {
	items   []modelcleanup.Item
	actions map[string]plannedAction
	runner  Runner
	mu      sync.Mutex
}

type plannedAction struct {
	targets      []string
	commands     []Command
	requiresRoot bool
}

// New 建立使用指定 catalog 與 command runner 的 cleanup service。
func New(definitions []Definition, runner Runner) *Service {
	if runner == nil {
		runner = NewOSRunner()
	}
	return &Service{
		definitions: append([]Definition(nil), definitions...),
		runner:      runner,
	}
}

// Items 回傳不含 execution details 的 preview snapshot。
func (p *Plan) Items() []modelcleanup.Item {
	return append([]modelcleanup.Item(nil), p.items...)
}

// Apply 套用 preview snapshot 中已確認的 item。
func (p *Plan) Apply(ctx context.Context, id string) error {
	p.mu.Lock()
	defer p.mu.Unlock()

	action, ok := p.actions[id]
	if !ok {
		return fmt.Errorf("unknown cleanup item %q", id)
	}
	if err := applyTargets(ctx, p.runner, action); err != nil {
		return fmt.Errorf("apply cleanup item %q: %w", id, err)
	}
	if err := runCommands(ctx, p.runner, action); err != nil {
		return fmt.Errorf("apply cleanup item %q: %w", id, err)
	}
	return nil
}

func applyTargets(ctx context.Context, runner Runner, action plannedAction) error {
	if len(action.targets) == 0 {
		return nil
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	if action.requiresRoot {
		args := append([]string{"rm", "-rf", "--"}, action.targets...)
		if err := runner.Run(ctx, "sudo", args...); err != nil {
			return fmt.Errorf("remove root-owned targets: %w", err)
		}
		return nil
	}

	for _, target := range action.targets {
		if err := ctx.Err(); err != nil {
			return err
		}
		if err := os.RemoveAll(target); err != nil {
			return fmt.Errorf("remove %s: %w", target, err)
		}
	}
	return nil
}

func runCommands(ctx context.Context, runner Runner, action plannedAction) error {
	for _, command := range action.commands {
		name := command.Name
		args := command.Args
		if action.requiresRoot {
			name = "sudo"
			args = append([]string{command.Name}, command.Args...)
		}
		if err := runner.Run(ctx, name, args...); err != nil {
			return fmt.Errorf("run %s: %w", command.Name, err)
		}
	}
	return nil
}
