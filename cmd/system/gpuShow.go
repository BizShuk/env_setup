package system

import (
	"io"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

func newGPUShowCommand(service *systemsvc.Service, out, errOut io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "show",
		Short: "顯示 GPU 型號",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.Show(command.Context(), "gpu", out, errOut)
		},
	}
}
