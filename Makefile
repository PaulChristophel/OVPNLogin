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
	go build -o $(debug_dir)/${BINARY_NAME} main.go
	go build -o $(debug_dir)/ip_fake ip_fake/main.go
	go build -o $(debug_dir)/checkpath checkpath/main.go
	go build -o $(debug_dir)/alive alive/main.go
else
	go build -ldflags="-w -s" -o $(release_dir)/${BINARY_NAME} main.go
	go build -ldflags="-w -s" -o $(release_dir)/ip_fake ip_fake/main.go
	go build -ldflags="-w -s" -o $(release_dir)/checkpath checkpath/main.go
	go build -ldflags="-w -s" -o $(release_dir)/alive alive/main.go
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
	rm -f $(debug_dir)/* $(release_dir)/*

podman:
	podman pull golang:alpine
	podman pull docker.io/alpine/k8s:1.28.3
	podman pull alpine:edge
	podman build . -t oitacr.azurecr.io/pmartin47/openvpn:latest --target=app
	podman build . -t oitacr.azurecr.io/pmartin47/openvpn:slim --target=slim

push:
	podman push oitacr.azurecr.io/pmartin47/openvpn:latest
	podman push oitacr.azurecr.io/pmartin47/openvpn:slim
