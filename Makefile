BINARY_NAME=ovpn_login
OS := $(shell uname -s)
src_dir = $(CURDIR)
build_dir = $(CURDIR)/bin
debug_dir = $(build_dir)/debug
release_dir = $(build_dir)/release
IMAGE_NAME = $(shell jq -r '.image' images.json)
GOLANG_IMAGE = $(shell jq -r '.build.golang_image' images.json)
K8S_IMAGE = $(shell jq -r '.build.k8s_image' images.json)
ALPINE_IMAGE = $(shell jq -r '.build.alpine_image' images.json)
OPENVPN_VERSION = $(shell jq -r '.openvpn.version' images.json)
OPENVPN_SHA512 = $(shell jq -r '.openvpn.sha512' images.json)
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
	/opt/homebrew/bin/podman pull $(GOLANG_IMAGE)
	/opt/homebrew/bin/podman pull $(K8S_IMAGE)
	/opt/homebrew/bin/podman pull $(ALPINE_IMAGE)
	/opt/homebrew/bin/podman build --platform=linux/amd64 --build-arg=GOLANG_IMAGE=$(GOLANG_IMAGE) --build-arg=K8S_IMAGE=$(K8S_IMAGE) --build-arg=ALPINE_IMAGE=$(ALPINE_IMAGE) --build-arg=OPENVPN_VERSION=$(OPENVPN_VERSION) --build-arg=OPENVPN_SHA512=$(OPENVPN_SHA512) --target=app -t $(IMAGE_NAME):latest -t $(IMAGE_NAME):$(OPENVPN_VERSION) .
	/opt/homebrew/bin/podman build --platform=linux/amd64 --build-arg=GOLANG_IMAGE=$(GOLANG_IMAGE) --build-arg=K8S_IMAGE=$(K8S_IMAGE) --build-arg=ALPINE_IMAGE=$(ALPINE_IMAGE) --build-arg=OPENVPN_VERSION=$(OPENVPN_VERSION) --build-arg=OPENVPN_SHA512=$(OPENVPN_SHA512) --target=slim -t $(IMAGE_NAME):slim -t $(IMAGE_NAME):slim-$(OPENVPN_VERSION) .
	
podman-push:
	/opt/homebrew/bin/podman push $(IMAGE_NAME):latest
	/opt/homebrew/bin/podman push $(IMAGE_NAME):$(OPENVPN_VERSION)
	/opt/homebrew/bin/podman push $(IMAGE_NAME):slim
	/opt/homebrew/bin/podman push $(IMAGE_NAME):slim-$(OPENVPN_VERSION)

helm:
	/opt/homebrew/bin/helm dependency update ./openvpn-router
	/opt/homebrew/bin/helm lint ./openvpn-router
	/opt/homebrew/bin/helm package --version 0.0.0 ./openvpn-router
	/opt/homebrew/bin/helm package ./openvpn-router

helm-push:
	/opt/homebrew/bin/helm push ./openvpn-router-0.0.0.tgz oci://harbor.oit.gatech.edu/ai
	/opt/homebrew/bin/helm push ./openvpn-router-$(shell yq -r .version openvpn-router/Chart.yaml).tgz oci://harbor.oit.gatech.edu/ai
