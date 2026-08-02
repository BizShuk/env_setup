package install

import (
	"io"

	installsvc "github.com/bizshuk/env_setup/svc/install"
	"github.com/spf13/cobra"
)

func newVSCodeExtensionCommand(
	service *installsvc.Service,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
) *cobra.Command {
	return &cobra.Command{
		Use:   "vscode-extension",
		Short: "從 manifest 安裝並同步 VS Code extensions",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.InstallVSCodeExtensions(command.Context(), in, out, errOut)
		},
	}
}
