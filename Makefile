BINARY_NAME=ovpn_login
OS := $(shell uname -s)
src_dir = $(CURDIR)
build_dir = $(CURDIR)/bin
debug_dir = $(build_dir)/debug
release_dir = $(build_dir)/release
.DEFAULT_GOAL := build
mode = dev

build: clean tidy test
	mkdir -p $(debug_dir) $(release_dir)
ifeq ($(mode), dev)
	go build -o $(debug_dir)/${BINARY_NAME}
else
	go build -o $(release_dir)/${BINARY_NAME}
endif

upgrade:
	go get -u ./...

tidy:
	go mod tidy

test:
	go test

clean:
	go clean
	go fmt ./...
	rm -f $(debug_dir)/${BINARY_NAME} $(release_dir)/${BINARY_NAME}
