package main

import (
	"github.com/spf13/cobra"
)

func newGreetCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "greet",
		Short: "Greets a user by name",
		Long:  `A command to greet a user by a specified name.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			name, _ := cmd.Flags().GetString("name")
			if name == "" {
				name = "there"
			}
			cmd.Printf("Hello, %s!\n", name)
			return nil
		},
	}
	cmd.Flags().StringP("name", "n", "", "Name to greet")
	return cmd
}
