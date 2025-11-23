package main

import (
	"fmt"

	"github.com/spf13/cobra"
)

func newListCmd() *cobra.Command {
	return &cobra.Command{
		Use:   "list",
		Short: "Lists all available commands",
		Long:  `A command to list all available commands in this application.`,
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Available Commands:")
			for _, c := range cmd.Parent().Commands() {
				if c.IsAvailableCommand() && c.Name() != "help" {
					fmt.Printf("- %s: %s\n", c.Name(), c.Short)
				}
			}
		},
	}
}
