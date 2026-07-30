package dump

import (
	"io"

	dumpsvc "github.com/bizshuk/env_setup/svc/dump"
	"github.com/spf13/cobra"
)

func newMacCommand(service *dumpsvc.Service, out, errOut io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "mac",
		Short: "匯出 Homebrew、casks、taps 與 Mac App Store manifest",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return service.DumpMac(command.Context(), out, errOut)
		},
	}
}
