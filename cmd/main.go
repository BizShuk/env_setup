package main

import (
	"github.com/spf13/cobra"
)

func RootCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "Shuk Usage",
		Short: "Shuk Usage",
		Long:  ``,
		Run: func(cmd *cobra.Command, args []string) {
			// Do Stuff Here
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
	RootCmd().Execute()
}
