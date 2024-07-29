.PHONY: api assets build docker

NODE_PATH ?= $(PWD)/ui/node_modules
assets:
	@if [ ! -d "$(NODE_PATH)"  ]; then cd ./ui && yarn install --modules-folder $(NODE_PATH); fi
	cd ./ui && yarn build --modules-folder $(NODE_PATH)

# This target skips the overhead of building UI assets.
# Intended to be used during development.
api:
	go build -o api ./cmd/asynqmon

# Build a release binary.
build: assets
	go build -o asynqmon ./cmd/asynqmon

# Build image and run Asynqmon server (with default settings).
docker:
	docker build --platform linux/amd64 -t asynqmon .
	docker run --rm \
		--name asynqmon \
		-p 8080:8080 \
		asynqmon --redis-addr=host.docker.internal:6379

build_docker_local:
	docker run -d -p 8080:5000 --name registry registry:latest
	sleep 5

	docker buildx create --driver-opt network=host --name multi-arch --use

	docker buildx build --platform linux/amd64,linux/arm64 --push -t localhost:8080/asynqmon:latest .
	docker pull localhost:8080/asynqmon:latest
	docker image tag localhost:8080/asynqmon:latest asynqmon:latest
	docker rmi localhost:8080/asynqmon:latest

	docker buildx rm multi-arch

	docker stop registry
	docker rm registry