BINARY_NAME=ovpn_login
OS := $(shell uname -s)
src_dir = $(CURDIR)
build_dir = $(CURDIR)/bin
debug_dir = $(build_dir)/debug
release_dir = $(build_dir)/release
K8S_IMAGE = docker.io/alpine/k8s:1.36.2
ALPINE_IMAGE = docker.io/library/alpine:3.24.1
OPENVPN_VERSION = 2.7.5
.DEFAULT_GOAL := build
mode = dev

build: clean tidy test lint
	mkdir -p $(debug_dir) $(release_dir)
ifeq ($(mode), dev)
	CGO_ENABLED=0 go build -o $(debug_dir)/${BINARY_NAME} main.go
	CGO_ENABLED=0 go build -o $(debug_dir)/ip_fake ip_fake/main.go
	CGO_ENABLED=0 go build -o $(debug_dir)/checkpath checkpath/main.go
	CGO_ENABLED=0 go build -o $(debug_dir)/alive alive/main.go
else
	CGO_ENABLED=0 go build -ldflags="-w -s" -o $(release_dir)/${BINARY_NAME} main.go
	CGO_ENABLED=0 go build -ldflags="-w -s" -o $(release_dir)/ip_fake ip_fake/main.go
	CGO_ENABLED=0 go build -ldflags="-w -s" -o $(release_dir)/checkpath checkpath/main.go
	CGO_ENABLED=0 go build -ldflags="-w -s" -o $(release_dir)/alive alive/main.go
endif

upgrade:
	go mod tidy
	go get -u ./...
	go mod tidy

fix:
	go fix ./...

tidy:
	go mod tidy

test:
	go test

lint:
	golangci-lint run

clean:
	go clean
	go fmt ./...
	rm -f $(debug_dir)/* $(release_dir)/*

podman:
	/opt/homebrew/bin/podman pull golang:alpine
	/opt/homebrew/bin/podman pull $(K8S_IMAGE)
	/opt/homebrew/bin/podman pull $(ALPINE_IMAGE)
	/opt/homebrew/bin/podman build . --platform=linux/amd64 --build-arg=K8S_IMAGE=$(K8S_IMAGE) --build-arg=ALPINE_IMAGE=$(ALPINE_IMAGE) --build-arg=OPENVPN_VERSION=$(OPENVPN_VERSION) -t docker.io/pcm0/openvpn:latest -t docker.io/pcm0/openvpn:$(OPENVPN_VERSION) --target=app
	/opt/homebrew/bin/podman build . --platform=linux/amd64 --build-arg=K8S_IMAGE=$(K8S_IMAGE) --build-arg=ALPINE_IMAGE=$(ALPINE_IMAGE) --build-arg=OPENVPN_VERSION=$(OPENVPN_VERSION) -t docker.io/pcm0/openvpn:slim -t docker.io/pcm0/openvpn:slim-$(OPENVPN_VERSION) --target=slim
	
podman-push:
	/opt/homebrew/bin/podman push docker.io/pcm0/openvpn:latest
	/opt/homebrew/bin/podman push docker.io/pcm0/openvpn:$(OPENVPN_VERSION)
	/opt/homebrew/bin/podman push docker.io/pcm0/openvpn:slim
	/opt/homebrew/bin/podman push docker.io/pcm0/openvpn:slim-$(OPENVPN_VERSION)

helm:
	/opt/homebrew/bin/helm dependency update ./openvpn-router
	/opt/homebrew/bin/helm lint ./openvpn-router
	/opt/homebrew/bin/helm package --version 0.0.0 ./openvpn-router
	/opt/homebrew/bin/helm package ./openvpn-router

helm-push:
	/opt/homebrew/bin/helm push ./openvpn-router-0.0.0.tgz oci://harbor.oit.gatech.edu/ai
	/opt/homebrew/bin/helm push ./openvpn-router-$(shell yq -r .version openvpn-router/Chart.yaml).tgz oci://harbor.oit.gatech.edu/ai
