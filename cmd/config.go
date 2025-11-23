package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

const configFileName = "config.json"

// readConfig reads the configuration from config.json
func readConfig() (map[string]string, error) {
	configPath := filepath.Join(".", configFileName) // Store in current directory
	data, err := os.ReadFile(configPath)
	if err != nil {
		if os.IsNotExist(err) {
			return make(map[string]string), nil // Return empty map if file doesn't exist
		}
		return nil, fmt.Errorf("error reading config file: %w", err)
	}

	var config map[string]string
	err = json.Unmarshal(data, &config)
	if err != nil {
		return nil, fmt.Errorf("error unmarshalling config data: %w", err)
	}
	return config, nil
}

// writeConfig writes the configuration to config.json
func writeConfig(config map[string]string) error {
	configPath := filepath.Join(".", configFileName) // Store in current directory
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return fmt.Errorf("error marshalling config data: %w", err)
	}

	err = os.WriteFile(configPath, data, 0644)
	if err != nil {
		return fmt.Errorf("error writing config file: %w", err)
	}
	return nil
}

func newConfigCmd() *cobra.Command {
	configCmd := &cobra.Command{
		Use:   "config",
		Short: "Manage configuration settings",
		Long:  `Allows setting and getting configuration values stored in a JSON file.`,
	}

	// Define the 'config set' subcommand
	var configSetCmd = &cobra.Command{
		Use:   "set",
		Short: "Set a configuration value",
		Long:  `Sets a key-value pair in the configuration.`,
		Run: func(cmd *cobra.Command, args []string) {
			key, _ := cmd.Flags().GetString("key")
			value, _ := cmd.Flags().GetString("value")

			if key == "" || value == "" {
				fmt.Println("Error: --key and --value flags are required for 'config set'.")
				return
			}

			config, err := readConfig()
			if err != nil {
				fmt.Println(err)
				return
			}

			config[key] = value
			err = writeConfig(config)
			if err != nil {
				fmt.Println(err)
				return
			}
			fmt.Printf("Configuration set: %s = %s\n", key, value)
		},
	}
	configSetCmd.Flags().StringP("key", "k", "", "Configuration key")
	configSetCmd.Flags().StringP("value", "v", "", "Configuration value")
	configSetCmd.MarkFlagRequired("key")
	configSetCmd.MarkFlagRequired("value")

	// Define the 'config get' subcommand
	var configGetCmd = &cobra.Command{
		Use:   "get",
		Short: "Get a configuration value",
		Long:  `Gets the value for a specified configuration key.`,
		Run: func(cmd *cobra.Command, args []string) {
			key, _ := cmd.Flags().GetString("key")

			if key == "" {
				fmt.Println("Error: --key flag is required for 'config get'.")
				return
			}

			config, err := readConfig()
			if err != nil {
				fmt.Println(err)
				return
			}

			if val, ok := config[key]; ok {
				fmt.Printf("%s = %s\n", key, val)
			} else {
				fmt.Printf("Key '%s' not found in configuration.\n", key)
			}
		},
	}
	configGetCmd.Flags().StringP("key", "k", "", "Configuration key")
	configGetCmd.MarkFlagRequired("key")

	// Add subcommands to 'config'
	configCmd.AddCommand(configSetCmd)
	configCmd.AddCommand(configGetCmd)

	return configCmd
}
