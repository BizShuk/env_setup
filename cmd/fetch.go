package main

import (
	"errors"
	"fmt"
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
		RunE: func(cmd *cobra.Command, args []string) error {
			url, _ := cmd.Flags().GetString("url")
			if url == "" {
				return errors.New("--url flag is required")
			}

			client := &http.Client{
				Timeout: 10 * time.Second,
			}
			resp, err := client.Get(url)
			if err != nil {
				return err
			}
			defer resp.Body.Close()

			if resp.StatusCode != http.StatusOK {
				return fmt.Errorf("received status code %d from %s", resp.StatusCode, url)
			}

			body, err := io.ReadAll(resp.Body)
			if err != nil {
				return err
			}

			cmd.Println(string(body))
			return nil
		},
	}
	cmd.Flags().StringP("url", "u", "", "URL to fetch content from")
	cmd.MarkFlagRequired("url")

	return cmd
}
