package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

var configPathOverride string

func getConfigPath() (string, error) {
	if configPathOverride != "" {
		return configPathOverride, nil
	}
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("error getting home directory: %w", err)
	}
	return filepath.Join(homeDir, ".smain.json"), nil
}

// readConfig reads the configuration from the config file
func readConfig() (map[string]string, error) {
	configPath, err := getConfigPath()
	if err != nil {
		return nil, err
	}
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

// writeConfig writes the configuration to the config file
func writeConfig(config map[string]string) error {
	configPath, err := getConfigPath()
	if err != nil {
		return err
	}
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
		RunE: func(cmd *cobra.Command, args []string) error {
			key, _ := cmd.Flags().GetString("key")
			value, _ := cmd.Flags().GetString("value")

			if key == "" || value == "" {
				return fmt.Errorf("--key and --value flags are required for 'config set'")
			}

			config, err := readConfig()
			if err != nil {
				return err
			}

			config[key] = value
			err = writeConfig(config)
			if err != nil {
				return err
			}
			cmd.Printf("Configuration set: %s = %s\n", key, value)
			return nil
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
		RunE: func(cmd *cobra.Command, args []string) error {
			key, _ := cmd.Flags().GetString("key")

			if key == "" {
				return fmt.Errorf("--key flag is required for 'config get'")
			}

			config, err := readConfig()
			if err != nil {
				return err
			}

			if val, ok := config[key]; ok {
				cmd.Printf("%s = %s\n", key, val)
			} else {
				cmd.Printf("Key '%s' not found in configuration.\n", key)
			}
			return nil
		},
	}
	configGetCmd.Flags().StringP("key", "k", "", "Configuration key")
	configGetCmd.MarkFlagRequired("key")

	// Add subcommands to 'config'
	configCmd.AddCommand(configSetCmd)
	configCmd.AddCommand(configGetCmd)

	return configCmd
}
