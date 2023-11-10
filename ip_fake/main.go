package main

import (
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
	if parentCmd != "/sbin/openvpn" {
		log.Fatalf("This program can only be executed by /sbin/openvpn, not %s", parentCmd)
	}

	file, err := os.OpenFile("/var/lib/openvpn/tmp/ip_res", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
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
