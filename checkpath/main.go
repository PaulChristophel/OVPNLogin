package main

import (
	"os"
)

func main() {
	if len(os.Args) < 2 {
		os.Exit(1)
	}

	path := os.Args[1]

	if _, err := os.Stat(path); os.IsNotExist(err) {
		os.Exit(1)
	}

	os.Exit(0)
}
