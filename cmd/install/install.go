// Package install implements the env_setup install command hierarchy.
package install

import (
	"io"

	installsvc "github.com/bizshuk/env_setup/svc/install"
	"github.com/spf13/cobra"
)

// NewCommand creates the root install command.
func NewCommand(service *installsvc.Service, in io.Reader, out, errOut io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "install",
		Short: "從 tracked manifests 安裝開發工具狀態",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(newAntigravityExtensionCommand(service, in, out, errOut))
	command.AddCommand(newVSCodeExtensionCommand(service, in, out, errOut))
	return command
}
