package main

import (
	"errors"

	"github.com/spf13/cobra"
)

func newCalcCmd() *cobra.Command {
	var num1 int
	var num2 int
	var operation string

	cmd := &cobra.Command{
		Use:   "calc",
		Short: "Performs simple arithmetic operations",
		Long:  `A command to perform addition or subtraction on two numbers.`,
		RunE: func(cmd *cobra.Command, args []string) error {
			switch operation {
			case "add":
				cmd.Printf("Result: %d\n", num1+num2)
				return nil
			case "sub":
				cmd.Printf("Result: %d\n", num1-num2)
				return nil
			default:
				return errors.New("invalid operation. Use 'add' or 'sub'")
			}
		},
	}

	cmd.Flags().IntVar(&num1, "num1", 0, "First number")
	cmd.Flags().IntVar(&num2, "num2", 0, "Second number")
	cmd.Flags().StringVarP(&operation, "operation", "o", "", "Operation to perform (add or sub)")
	cmd.MarkFlagRequired("num1")
	cmd.MarkFlagRequired("num2")
	cmd.MarkFlagRequired("operation")

	return cmd
}
