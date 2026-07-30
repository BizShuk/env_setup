// Package system 實作 env_setup system Cobra command hierarchy。
package system

import (
	"io"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

// NewCommand 建立 root command 底下的 system subcommand。
func NewCommand(service *systemsvc.Service, out, errOut io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "system",
		Short: "顯示硬體與系統資訊",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(
		newShowCommand(service, out, errOut),
		newOSCommand(service, out, errOut),
		newCPUCommand(service, out, errOut),
		newMemoryCommand(service, out, errOut),
		newGPUCommand(service, out, errOut),
		newDiskCommand(service, out, errOut),
		newUSBCommand(service, out, errOut),
		newDisplayCommand(service, out, errOut),
		newNetworkCommand(service, out, errOut),
		newInputCommand(service, out, errOut),
		newAudioCommand(service, out, errOut),
	)
	return command
}
