package uninstall

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"strings"
	"text/tabwriter"

	uninstallsvc "github.com/bizshuk/env_setup/svc/uninstall"
	"github.com/spf13/cobra"
)

func newCodexCommand(
	service *uninstallsvc.Service,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
) *cobra.Command {
	var apply bool
	var withCodexBar bool
	var purgeSystem bool
	command := &cobra.Command{
		Use:   "codex",
		Short: "Preview or remove the Codex app, CLI, and local data",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return runCodex(
				command.Context(),
				service,
				in,
				out,
				errOut,
				apply,
				withCodexBar,
				purgeSystem,
			)
		},
	}
	command.Flags().BoolVar(
		&apply,
		"apply",
		false,
		"逐項確認後移除已發現的 Codex artifacts",
	)
	command.Flags().BoolVar(
		&withCodexBar,
		"with-codexbar",
		false,
		"將 CodexBar.app 加入 preview 與 confirmation scope",
	)
	command.Flags().BoolVar(
		&purgeSystem,
		"purge-system",
		false,
		"將 /Library 與 /etc Codex artifacts 加入 sudo removal scope",
	)
	return command
}

func runCodex(
	ctx context.Context,
	service *uninstallsvc.Service,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
	apply bool,
	withCodexBar bool,
	purgeSystem bool,
) error {
	plan, err := service.InspectCodex(ctx, uninstallsvc.CodexOptions{
		WithCodexBar: withCodexBar,
		PurgeSystem:  purgeSystem,
	})
	if err != nil {
		return fmt.Errorf("inspect Codex uninstall targets: %w", err)
	}
	items := plan.Items()
	if err := printCodexItems(out, items); err != nil {
		return fmt.Errorf("print Codex uninstall targets: %w", err)
	}

	if !apply {
		fmt.Fprintln(out)
		fmt.Fprintln(
			out,
			"Preview mode：未修改任何 Codex artifact。實際執行請使用 `"+
				codexApplyCommand(withCodexBar, purgeSystem)+
				"`。",
		)
		return nil
	}

	fmt.Fprintln(out)
	fmt.Fprintln(out, "Apply mode：每個 available target 都必須個別確認，預設為 No。")
	reader := bufio.NewReader(in)
	var applied int
	var skipped int
	var failed int
	var applyErrors []error
	for _, item := range items {
		if !item.Available {
			continue
		}
		if !confirmCodexItem(reader, out, item) {
			fmt.Fprintf(out, "  - skipped %s\n", item.ID)
			skipped++
			continue
		}
		if err := plan.Apply(ctx, item.ID, out, errOut); err != nil {
			fmt.Fprintf(out, "  ✗ failed %s：%v\n", item.ID, err)
			applyErrors = append(applyErrors, err)
			failed++
			continue
		}
		fmt.Fprintf(out, "  ✓ applied %s\n", item.ID)
		applied++
	}
	fmt.Fprintf(
		out,
		"\nSummary：applied=%d skipped=%d failed=%d\n",
		applied,
		skipped,
		failed,
	)
	return errors.Join(applyErrors...)
}

func printCodexItems(out io.Writer, items []uninstallsvc.Item) error {
	writer := tabwriter.NewWriter(out, 0, 4, 2, ' ', 0)
	fmt.Fprintln(writer, "ID\tSCOPE\tTARGET\tDESCRIPTION\tSTATUS")
	for _, item := range items {
		status := "ready"
		if !item.Available {
			status = "not found"
		}
		fmt.Fprintf(
			writer,
			"%s\t%s\t%s\t%s\t%s\n",
			item.ID,
			item.Scope,
			item.Target,
			item.Description,
			status,
		)
	}
	return writer.Flush()
}

func confirmCodexItem(
	reader *bufio.Reader,
	out io.Writer,
	item uninstallsvc.Item,
) bool {
	fmt.Fprintf(
		out,
		"移除 %s（%s）— %s？ [y/N] ",
		item.Target,
		item.Scope,
		item.Description,
	)
	answer, err := reader.ReadString('\n')
	if err != nil && len(answer) == 0 {
		return false
	}
	switch strings.ToLower(strings.TrimSpace(answer)) {
	case "y", "yes":
		return true
	default:
		return false
	}
}

func codexApplyCommand(withCodexBar, purgeSystem bool) string {
	command := "env_setup uninstall codex --apply"
	if withCodexBar {
		command += " --with-codexbar"
	}
	if purgeSystem {
		command += " --purge-system"
	}
	return command
}
