package install

import (
	"io"

	installsvc "github.com/bizshuk/env_setup/svc/install"
	"github.com/spf13/cobra"
)

func newAntigravityExtensionCommand(
	service *installsvc.Service,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
) *cobra.Command {
	return &cobra.Command{
		Use:   "antigravity-extension",
		Short: "從 manifest 安裝並同步 Antigravity IDE extensions",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.InstallAntigravityExtensions(command.Context(), in, out, errOut)
		},
	}
}
