package main

import (
	"log"
	"os"
	"strings"
)

func main() {
	file, err := os.OpenFile("/var/lib/openvpn/ip_res", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	// Join the arguments with space, similar to how "$@" behaves in shell script
	args := strings.Join(os.Args[1:], " ") + "\n"

	if _, err := file.WriteString(args); err != nil {
		log.Fatal(err)
	}
}
