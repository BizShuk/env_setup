// Package uninstall implements the env_setup uninstall command hierarchy.
package uninstall

import (
	"io"

	uninstallsvc "github.com/bizshuk/env_setup/svc/uninstall"
	"github.com/spf13/cobra"
)

// NewCommand creates the root uninstall command.
func NewCommand(
	service *uninstallsvc.Service,
	in io.Reader,
	out io.Writer,
	errOut io.Writer,
) *cobra.Command {
	command := &cobra.Command{
		Use:   "uninstall",
		Short: "Preview and remove local development-tool artifacts",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(newCodexCommand(service, in, out, errOut))
	return command
}
