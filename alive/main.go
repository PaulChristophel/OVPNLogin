package main

import (
	"flag"
	"log"
	"os"
)

func main() {
	// Define a command line flag
	downFlag := flag.Bool("down", false, "Set this flag to delete the file.")
	flag.Parse() // Parse the flags

	path := "/var/lib/openvpn/tmp/alive"

	if *downFlag {
		// If the down flag is set, delete the file
		err := os.Remove(path)
		if err != nil {
			log.Fatalf("Error deleting file: %v", err)
		}
	} else {
		// Default behavior: Create the directory and file
		if err := os.MkdirAll("/var/lib/openvpn/tmp", os.ModePerm); err != nil {
			log.Printf("Error creating directories: %v", err)
		}

		// Create an empty file
		file, err := os.OpenFile(path, os.O_CREATE|os.O_RDONLY, 0644)
		if err != nil {
			log.Fatalf("Error creating file: %v", err)
		}
		file.Close() // Close the file immediately as we're just creating it
	}
}
