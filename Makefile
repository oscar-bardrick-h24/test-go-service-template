GO = go
BIN = bin/example
DOCKER = docker
DOCKER_IMAGE = home24/goservice-template
DOCKER_TAG ?= latest
AWS ?= aws

.PHONY: build
build: clean $(BIN)
	$(DOCKER) build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

$(BIN):
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 $(GO) build -o $@ cmd/example/main.go

.PHONY: clean
clean:
	rm -f $(BIN)

.PHONY: test
test:
	$(GO) test ./...

.PHONY: lint
lint:
	golangci-lint run ./...

.PHONY: push-dockerhub
push-dockerhub:
	docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

.PHONY: push-ecr
push-ecr:
	# make sure ECR_DOCKER_IMAGE is set
	test -n "$(ECR_DOCKER_IMAGE)"

	# refresh ECR credentials
	$$($(AWS) ecr get-login --no-include-email)

	# validate that credentials are actually valid
	echo -n | docker login $(ECR_DOCKER_IMAGE) >/dev/null 2>&1 || (echo "Not logged in for docker registry. Please login to AWS using sso or other means"; exit 1)

	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(ECR_DOCKER_IMAGE)
	docker push $(ECR_DOCKER_IMAGE)
