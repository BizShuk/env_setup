// Package dump implements the env_setup dump command hierarchy.
package dump

import (
	"io"

	dumpsvc "github.com/bizshuk/env_setup/svc/dump"
	"github.com/spf13/cobra"
)

// NewCommand creates the root dump command.
func NewCommand(service *dumpsvc.Service, out, errOut io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "dump",
		Short: "匯出 macOS 與 IDE manifests",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(
		newMacCommand(service, out, errOut),
		newVSCodeExtensionCommand(service, out, errOut),
		newAntigravityExtensionCommand(service, out, errOut),
	)
	return command
}
