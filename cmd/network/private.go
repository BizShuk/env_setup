package network

import (
	"io"

	networksvc "github.com/bizshuk/env_setup/svc/network"
	"github.com/spf13/cobra"
)

func newPrivateCommand(service *networksvc.Service, out, errOut io.Writer) *cobra.Command {
	var outputPath string
	command := &cobra.Command{
		Use:   "private [target]",
		Short: "追蹤 private route 並產生 subnet topology",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(command *cobra.Command, args []string) error {
			target := ""
			if len(args) == 1 {
				target = args[0]
			}
			return service.ScanPrivate(
				command.Context(),
				out,
				errOut,
				networksvc.PrivateOptions{
					Target:     target,
					OutputPath: outputPath,
				},
			)
		},
	}
	command.Flags().StringVarP(
		&outputPath,
		"output",
		"o",
		"network.topo",
		"topology output file",
	)
	return command
}
