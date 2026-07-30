// Package network implements the env_setup network Cobra hierarchy.
package network

import (
	"io"

	networksvc "github.com/bizshuk/env_setup/svc/network"
	"github.com/spf13/cobra"
)

// NewCommand creates the root-level network subcommand.
func NewCommand(service *networksvc.Service, out, errOut io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "network",
		Short: "掃描 target network 與 private route topology",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(
		newPrivateCommand(service, out, errOut),
		newTargetCommand(service, out, errOut),
	)
	return command
}
