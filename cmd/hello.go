package main

import (
	log "github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
)

func newHelloCmd() *cobra.Command {
	return &cobra.Command{
		Use:     "hello",
		Aliases: []string{"hi"},
		Short:   "Says hello",
		Long:    `A simple command to say hello.`,
		Run: func(cmd *cobra.Command, args []string) {
			log.Println("Hello, world!")
		},
	}
}
