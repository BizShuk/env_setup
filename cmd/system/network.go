package system

import (
	"io"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

func newNetworkCommand(service *systemsvc.Service, out, errOut io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "network",
		Short: "網路介面與 IP 資訊",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(newNetworkShowCommand(service, out, errOut))
	return command
}
