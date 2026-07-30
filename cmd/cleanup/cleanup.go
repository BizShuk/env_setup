// Package cleanup 實作 env_setup cleanup Cobra command。
package cleanup

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"strings"
	"text/tabwriter"

	modelcleanup "github.com/bizshuk/env_setup/model/cleanup"
	cleanupsvc "github.com/bizshuk/env_setup/svc/cleanup"
	"github.com/spf13/cobra"
)

// NewCommand 建立預設為 preview、以 --apply 啟用逐項確認的 cleanup command。
func NewCommand(service *cleanupsvc.Service, in io.Reader, out io.Writer) *cobra.Command {
	var apply bool
	command := &cobra.Command{
		Use:   "cleanup",
		Short: "列出並選擇性清理 macOS caches 與 temporary data",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return run(command.Context(), service, in, out, apply)
		},
	}
	command.Flags().BoolVar(&apply, "apply", false, "逐項確認後執行已選擇的 cleanup item")
	return command
}

func run(ctx context.Context, service *cleanupsvc.Service, in io.Reader, out io.Writer, apply bool) error {
	plan, err := service.Inspect(ctx)
	if err != nil {
		return fmt.Errorf("inspect cleanup items: %w", err)
	}
	items := plan.Items()
	if err := printItems(out, items); err != nil {
		return fmt.Errorf("print cleanup items: %w", err)
	}

	if !apply {
		fmt.Fprintln(out)
		fmt.Fprintln(out, "Preview mode：未修改任何檔案。實際執行請使用 `env_setup cleanup --apply`。")
		return nil
	}

	fmt.Fprintln(out)
	fmt.Fprintln(out, "Apply mode：每個 item 都必須個別確認，預設為 No。")
	reader := bufio.NewReader(in)
	var applied, skipped, failed int
	var applyErrors []error

	for _, item := range items {
		if !item.Available {
			continue
		}
		if !confirm(reader, out, item) {
			fmt.Fprintf(out, "  - skipped %s\n", item.ID)
			skipped++
			continue
		}
		if err := plan.Apply(ctx, item.ID); err != nil {
			fmt.Fprintf(out, "  ✗ failed %s：%v\n", item.ID, err)
			applyErrors = append(applyErrors, err)
			failed++
			continue
		}
		fmt.Fprintf(out, "  ✓ applied %s\n", item.ID)
		applied++
	}

	fmt.Fprintf(out, "\nSummary：applied=%d skipped=%d failed=%d\n", applied, skipped, failed)
	return errors.Join(applyErrors...)
}

func printItems(out io.Writer, items []modelcleanup.Item) error {
	writer := tabwriter.NewWriter(out, 0, 4, 2, ' ', 0)
	fmt.Fprintln(writer, "ID\tSIZE\tDESCRIPTION\tSTATUS")
	var total int64
	var unknownSize bool
	for _, item := range items {
		status := "ready"
		if !item.Available {
			status = "not found"
		}
		size := itemSize(item)
		if item.SizeKnown {
			total += item.SizeBytes
		} else {
			unknownSize = true
		}
		fmt.Fprintf(writer, "%s\t%s\t%s\t%s\n", item.ID, size, item.Description, status)
	}
	if err := writer.Flush(); err != nil {
		return err
	}

	suffix := ""
	if unknownSize {
		suffix = " + N/A items"
	}
	_, err := fmt.Fprintf(out, "\nItem size sum（可能有重疊）：%s%s\n", formatBytes(total), suffix)
	return err
}

func confirm(reader *bufio.Reader, out io.Writer, item modelcleanup.Item) bool {
	fmt.Fprintf(out, "套用 %s（%s）— %s？ [y/N] ", item.ID, itemSize(item), item.Description)
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

func itemSize(item modelcleanup.Item) string {
	if !item.SizeKnown {
		return "N/A"
	}
	return formatBytes(item.SizeBytes)
}

func formatBytes(size int64) string {
	const unit = int64(1024)
	if size < unit {
		return fmt.Sprintf("%d B", size)
	}
	divisor := unit
	unitIndex := 0
	for value := size / unit; value >= unit && unitIndex < 4; value /= unit {
		divisor *= unit
		unitIndex++
	}
	units := []string{"KiB", "MiB", "GiB", "TiB", "PiB"}
	return fmt.Sprintf("%.1f %s", float64(size)/float64(divisor), units[unitIndex])
}
