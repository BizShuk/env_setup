package dump

import (
	"io"

	dumpsvc "github.com/bizshuk/env_setup/svc/dump"
	"github.com/spf13/cobra"
)

func newVSCodeExtensionCommand(service *dumpsvc.Service, out, errOut io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "vscode-extension",
		Short: "匯出 VS Code extensions manifest",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.DumpVSCode(command.Context(), out, errOut)
		},
	}
}
