package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

func newLsCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "ls",
		Short: "Lists directory contents",
		Long:  `A command to list files and directories in a specified path.`,
		Run: func(cmd *cobra.Command, args []string) {
			path, _ := cmd.Flags().GetString("path")

			files, err := os.ReadDir(path)
			if err != nil {
				fmt.Printf("Error reading directory %s: %v\n", path, err)
				return
			}

			for _, file := range files {
				fmt.Println(file.Name())
			}
		},
	}
	cmd.Flags().StringP("path", "p", ".", "Path to the directory to list")

	return cmd
}
