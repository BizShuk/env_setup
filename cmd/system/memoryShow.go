package system

import (
	"io"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

func newMemoryShowCommand(service *systemsvc.Service, out, errOut io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "show",
		Short: "顯示記憶體容量",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.Show(command.Context(), "memory", out, errOut)
		},
	}
}
