package main

import (
	"fmt"

	"github.com/spf13/cobra"
)

func newGreetCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "greet",
		Short: "Greets a user by name",
		Long:  `A command to greet a user by a specified name.`,
		Run: func(cmd *cobra.Command, args []string) {
			name, _ := cmd.Flags().GetString("name")
			if name == "" {
				name = "there"
			}
			fmt.Printf("Hello, %s!\n", name)
		},
	}
	cmd.Flags().StringP("name", "n", "", "Name to greet")
	return cmd
}
