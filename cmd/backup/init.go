package backup

import (
	"io"

	svc "github.com/bizshuk/env_setup/svc/backup"
	"github.com/spf13/cobra"
)

func newInitCommand(out io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "init",
		Short: "建立預設 defaults domain manifest",
		Args:  cobra.NoArgs,
		RunE: func(_ *cobra.Command, _ []string) error {
			return svc.Init(out)
		},
	}
}
