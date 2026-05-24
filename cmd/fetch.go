package main

import (
	"io"
	"net/http"
	"time"

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
				cmd.Println("Error: --url flag is required.")
				return
			}

			client := &http.Client{
				Timeout: 10 * time.Second,
			}
			resp, err := client.Get(url)
			if err != nil {
				cmd.Printf("Error fetching URL: %v\n", err)
				return
			}
			defer resp.Body.Close()

			if resp.StatusCode != http.StatusOK {
				cmd.Printf("Error: Received status code %d from %s\n", resp.StatusCode, url)
				return
			}

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				cmd.Printf("Error reading response body: %v\n", err)
				return
			}

			cmd.Println(string(body))
		},
	}
	cmd.Flags().StringP("url", "u", "", "URL to fetch content from")
	cmd.MarkFlagRequired("url")

	return cmd
}
