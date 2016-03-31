PREFIX?=$(shell pwd)
DOCKER=docker
NAMESPACE=dmcgowan
GOFILES=$(wildcard *.go)

.PHONY: builderimage dockerimage fmt lint vet binaries build install clean all
.DEFAULT: all
all: fmt lint vet binaries

builderimage:
	@echo "+ $@"
	cd $(PREFIX);\
	$(DOCKER) build -f Dockerfile.builder -t $(NAMESPACE)/malevolent-builder:latest .

malevolent.alpine: builderimage $(GOFILES)
	@echo "+ $@"
	$(DOCKER) run -v $(PREFIX):/gopath/src/github.com/dmcgowan/malevolent $(NAMESPACE)/malevolent-builder sh -c "cd /gopath/src/github.com/dmcgowan/malevolent; godep go build -o malevolent.alpine ."

dockerimage: malevolent.alpine
	@echo "+ $@"
	cd $(PREFIX);\
	$(DOCKER) build -f Dockerfile.alpine -t $(NAMESPACE)/malevolent:latest  .

$(PREFIX)/malevolent:
	@echo "+ $@"
	@go build -o $@ ${GO_LDFLAGS} ${GO_GCFLAGS} .


fmt:
	@echo "+ $@"
	@test -z "$$(gofmt -s -l . | grep -v Godeps/_workspace/src/ | tee /dev/stderr)" || \
		echo "+ please format Go code with 'gofmt -s'"

lint:
	@echo "+ $@"
	@test -z "$$(golint ./... | grep -v Godeps/_workspace/src/ | tee /dev/stderr)"

build:
	@echo "+ $@"
	@go build -v ${GO_LDFLAGS} .

install:
	@echo "+ $@"
	@go install -v ${GO_LDFLAGS} .

binaries: ${PREFIX}/malevolent
	@echo "+ $@"

vet: binaries
	@echo "+ $@"
	@go vet ./...

clean: builderimage
	@echo "+ $@"
	@rm -rf "${PREFIX}/malevolent"

	$(DOCKER) run -v $(PREFIX):/gopath/src/github.com/dmcgowan/malevolent $(NAMESPACE)/malevolent-builder sh -c "cd /gopath/src/github.com/dmcgowan/malevolent; rm -f malevolent.alpine"
	$(DOCKER) rmi $(NAMESPACE)/malevolent-builder

