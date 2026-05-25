package main

import (
	"github.com/spf13/cobra"
)

func newHelloCmd() *cobra.Command {
	return &cobra.Command{
		Use:     "hello",
		Aliases: []string{"hi"},
		Short:   "Says hello",
		Long:    `A simple command to say hello.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			cmd.Println("Hello, world!")
			return nil
		},
	}
}
