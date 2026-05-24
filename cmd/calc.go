package main

import (
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
		Run: func(cmd *cobra.Command, args []string) {
			switch operation {
			case "add":
				cmd.Printf("Result: %d\n", num1+num2)
			case "sub":
				cmd.Printf("Result: %d\n", num1-num2)
			default:
				cmd.Println("Error: Invalid operation. Use 'add' or 'sub'.")
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
