package network

import (
	"io"

	networksvc "github.com/bizshuk/env_setup/svc/network"
	"github.com/spf13/cobra"
)

func newTargetCommand(service *networksvc.Service, out, errOut io.Writer) *cobra.Command {
	return &cobra.Command{
		Use:   "target [cidr]",
		Short: "探索指定 IPv4 CIDR 的 live hosts",
		Args:  cobra.MaximumNArgs(1),
		RunE: func(command *cobra.Command, args []string) error {
			target := ""
			if len(args) == 1 {
				target = args[0]
			}
			return service.ScanTarget(
				command.Context(),
				out,
				errOut,
				networksvc.TargetOptions{CIDR: target},
			)
		},
	}
}
