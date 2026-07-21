package main

import (
	"fmt"
	"net/http"
	"os"

	"golang-scratch/internal/server"
)

func main() {
	addr := ":8080"
	fmt.Fprintf(os.Stderr, "listening on %s\n", addr)
	if err := http.ListenAndServe(addr, server.NewMux()); err != nil {
		fmt.Fprintf(os.Stderr, "listen: %v\n", err)
		os.Exit(1)
	}
}
