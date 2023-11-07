package main

import (
	"flag"
	"log"
	"os"
)

func main() {
	downFlag := flag.Bool("down", false, "Set this flag to delete the file.")

	pathFlag := flag.String("path", "/var/lib/openvpn/tmp/alive", "The path to the file to create or delete.")

	flag.Parse()

	path := *pathFlag

	if *downFlag {
		err := os.Remove(path)
		if err != nil {
			log.Fatalf("Error deleting file: %v", err)
		}
	} else {
		dir := path[:len(path)-len(flag.Arg(0))]
		if err := os.MkdirAll(dir, os.ModePerm); err != nil {
			log.Printf("Error creating directories: %v", err)
		}

		file, err := os.OpenFile(path, os.O_CREATE|os.O_RDONLY, 0644)
		if err != nil {
			log.Fatalf("Error creating file: %v", err)
		}
		file.Close()
	}
}
