package dump

import (
	"io"

	dumpsvc "github.com/bizshuk/env_setup/svc/dump"
	"github.com/spf13/cobra"
)

func newAntigravityCommand(service *dumpsvc.Service, out, errOut io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "antigravity",
		Short: "匯出 Antigravity IDE extensions manifest",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.DumpAntigravity(command.Context(), out, errOut)
		},
	}
}
