TAG := `git describe --tags --always`
VERSION :=

## Adds a '-dirty' suffix to version string if there are uncommitted changes
changes := $(shell git status --porcelain)
ifeq ($(changes),)
	VERSION := $(TAG)
else
	VERSION := $(TAG)-dirty
endif

LDFLAGS := "-X main.version=$(VERSION) \
-X main.gadgetimage=docker.io/kinvolk/gadget:$(shell ./tools/image-tag branch) \
-extldflags '-static'"

.PHONY: build
build: build-ig build-gadget-container

.PHONY: build-ig
build-ig: kubectl-gadget-linux-amd64 kubectl-gadget-darwin-amd64

kubectl-gadget-linux-amd64:
	GO111MODULE=on CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
		-ldflags $(LDFLAGS) \
		-o kubectl-gadget-linux-amd64 \
		github.com/kinvolk/inspektor-gadget/cmd/kubectl-gadget

kubectl-gadget-darwin-amd64:
	GO111MODULE=on CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build \
		-ldflags $(LDFLAGS) \
		-o kubectl-gadget-darwin-amd64 \
		github.com/kinvolk/inspektor-gadget/cmd/kubectl-gadget

.PHONY: build-gadget-container
build-gadget-container:
	make -C gadget-container build

.PHONY: install-user
install-user: build-ig
	mkdir -p ~/.local/bin/
	cp kubectl-gadget ~/.local/bin/

.PHONY: test
test:
	go test ./...
