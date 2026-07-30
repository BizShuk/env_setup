package system

import (
	"io"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

func newDisplayCommand(service *systemsvc.Service, out, errOut io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "display",
		Short: "顯示器資訊",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(newDisplayShowCommand(service, out, errOut))
	return command
}
