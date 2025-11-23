package main

import (
	"fmt"
	"io"
	"net/http"

	"github.com/spf13/cobra"
)

func newFetchCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "fetch",
		Short: "Fetches content from a URL",
		Long:  `A command to fetch the content from a specified URL and print it.`,
		Run: func(cmd *cobra.Command, args []string) {
			url, _ := cmd.Flags().GetString("url")
			if url == "" {
				fmt.Println("Error: --url flag is required.")
				return
			}

			resp, err := http.Get(url)
			if err != nil {
				fmt.Printf("Error fetching URL: %v\n", err)
				return
			}
			defer resp.Body.Close()

			if resp.StatusCode != http.StatusOK {
				fmt.Printf("Error: Received status code %d from %s\n", resp.StatusCode, url)
				return
			}

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				fmt.Printf("Error reading response body: %v\n", err)
				return
			}

			fmt.Println(string(body))
		},
	}
	cmd.Flags().StringP("url", "u", "", "URL to fetch content from")
	cmd.MarkFlagRequired("url")

	return cmd
}
