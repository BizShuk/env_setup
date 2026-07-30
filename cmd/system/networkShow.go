package system

import (
	"io"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

func newNetworkShowCommand(service *systemsvc.Service, out, errOut io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "show",
		Short: "顯示本機網路介面與 IP 位址",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.Show(command.Context(), "network", out, errOut)
		},
	}
}
