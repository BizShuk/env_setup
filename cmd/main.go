package main

import (
	"os"

	"github.com/spf13/cobra"
)

func RootCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "smain",
		Short: "smain CLI tool",
		Long:  `A utility command-line tool for developers.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			// Do Stuff Here
			return nil
		},
	}

	// Add all top-level subcommands to the root command
	cmd.AddCommand(newHelloCmd())
	cmd.AddCommand(newGreetCmd())
	cmd.AddCommand(newCalcCmd())
	cmd.AddCommand(newFetchCmd())
	cmd.AddCommand(newLsCmd())
	cmd.AddCommand(newConfigCmd())
	cmd.AddCommand(newListCmd())

	return cmd
}

func main() {
	if err := RootCmd().Execute(); err != nil {
		os.Exit(1)
	}
}
