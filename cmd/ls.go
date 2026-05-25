package main

import (
	"os"

	"github.com/spf13/cobra"
)

func newLsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "ls",
		Short: "Lists directory contents",
		Long:  `A command to list files and directories in a specified path.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			path, _ := cmd.Flags().GetString("path")

			files, err := os.ReadDir(path)
			if err != nil {
				return err
			}

			for _, file := range files {
				cmd.Println(file.Name())
			}
			return nil
		},
	}
	cmd.Flags().StringP("path", "p", ".", "Path to the directory to list")

	return cmd
}
