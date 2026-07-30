package backup

import (
	"io"

	svc "github.com/bizshuk/env_setup/svc/backup"
	"github.com/spf13/cobra"
)

func newListCommand(out io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "顯示 latest backup date、defaults domain 與 backup 狀態",
		Args:  cobra.NoArgs,
		RunE: func(_ *cobra.Command, _ []string) error {
			return svc.List(out)
		},
	}
}
