package system

import (
	"io"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

func newOSCommand(service *systemsvc.Service, out, errOut io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "os",
		Short: "作業系統資訊",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(newOSShowCommand(service, out, errOut))
	return command
}
