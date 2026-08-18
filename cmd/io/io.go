// Package io 實作 env_setup io Cobra command hierarchy。
package io

import (
	"io"

	iosvc "github.com/bizshuk/env_setup/svc/io"
	"github.com/spf13/cobra"
)

// NewCommand 建立 root command 底下的 io subcommand。
func NewCommand(service *iosvc.Service, out, errOut io.Writer) *cobra.Command {
	command := &cobra.Command{
		Use:   "io",
		Short: "區塊裝置 I/O 能力探測",
		Args:  cobra.NoArgs,
		RunE: func(command *cobra.Command, _ []string) error {
			return command.Help()
		},
	}
	command.AddCommand(newProbeCommand(service, out, errOut))
	return command
}
