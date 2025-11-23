package main

import (
	"fmt"
	"strconv"

	"github.com/spf13/cobra"
)

func newCalcCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "calc",
		Short: "Performs simple arithmetic operations",
		Long:  `A command to perform addition or subtraction on two numbers.`,
		Run: func(cmd *cobra.Command, args []string) {
			num1Str, _ := cmd.Flags().GetString("num1")
			num2Str, _ := cmd.Flags().GetString("num2")
			operation, _ := cmd.Flags().GetString("operation")

			num1, err := strconv.Atoi(num1Str)
			if err != nil {
				fmt.Println("Error: --num1 must be an integer.")
				return
			}
			num2, err := strconv.Atoi(num2Str)
			if err != nil {
				fmt.Println("Error: --num2 must be an integer.")
				return
			}

			switch operation {
			case "add":
				fmt.Printf("Result: %d\n", num1+num2)
			case "sub":
				fmt.Printf("Result: %d\n", num1-num2)
			default:
				fmt.Println("Error: Invalid operation. Use 'add' or 'sub'.")
			}
		},
	}

	cmd.Flags().StringP("num1", "", "", "First number")
	cmd.Flags().StringP("num2", "", "", "Second number")
	cmd.Flags().StringP("operation", "o", "", "Operation to perform (add or sub)")
	cmd.MarkFlagRequired("num1")
	cmd.MarkFlagRequired("num2")
	cmd.MarkFlagRequired("operation")

	return cmd
}
