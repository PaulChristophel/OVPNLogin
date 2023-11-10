package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"
)

func main() {
	// Check if the parent process is /sbin/openvpn
	ppid := os.Getppid()
	procPath := fmt.Sprintf("/proc/%d/cmdline", ppid)

	// Read the cmdline file which contains the command line of the parent process
	cmdline, err := ioutil.ReadFile(procPath)
	if err != nil {
		log.Fatalf("Failed to read cmdline for PPID %d: %v", ppid, err)
	}

	// The cmdline argument is separated by NULL bytes; convert it to a string
	// and compare it to the desired parent process name
	parentCmd := strings.Split(string(cmdline), "\x00")[0]
	if parentCmd != "/sbin/openvpn" || parentCmd != "/usr/sbin/openvpn" {
		log.Fatalf("This program can only be executed by {/usr}/sbin/openvpn, not %s", parentCmd)
	}

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
