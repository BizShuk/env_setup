package main

import (
	"github.com/spf13/cobra"
)

func newListCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "Lists all available commands",
		Long:  `A command to list all available commands in this application.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			cmd.Println("Available Commands:")
			for _, c := range cmd.Parent().Commands() {
				if c.IsAvailableCommand() && c.Name() != "help" {
					cmd.Printf("- %s: %s\n", c.Name(), c.Short)
				}
			}
			return nil
		},
	}
}
