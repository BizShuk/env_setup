// Package backup 實作 macOS defaults backup Cobra commands。
package backup

import (
	"io"

	svc "github.com/bizshuk/env_setup/svc/backup"
	"github.com/spf13/cobra"
)

// NewCommand 建立 root command 底下的 backup subcommand。
func NewCommand(in io.Reader, out io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "backup",
		Short: "備份與匯入 macOS defaults domains",
		Args:  cobra.NoArgs,
		RunE: func(_ *cobra.Command, _ []string) error {
			return svc.Backup(out)
		},
	}
	command.AddCommand(
		newImportCommand(in, out),
		newListCommand(out),
		newInitCommand(out),
	)
	return command
}
