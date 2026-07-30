package system

import (
	"io"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

func newMemoryCommand(service *systemsvc.Service, out, errOut io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "memory",
		Short: "記憶體資訊",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(newMemoryShowCommand(service, out, errOut))
	return command
}
