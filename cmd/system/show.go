package system

import (
	"io"

	systemsvc "github.com/bizshuk/env_setup/svc/system"
	"github.com/spf13/cobra"
)

func newShowCommand(service *systemsvc.Service, out, errOut io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "show",
		Short: "顯示全部硬體與系統資訊",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.ShowAll(command.Context(), out, errOut)
		},
	}
}
