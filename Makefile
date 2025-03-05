DOCKERFILE_DIR := docker

UID := $(shell id -u)
GID := $(shell id -g)

builder:
	sudo docker build --build-arg UID=$(UID) --build-arg GID=$(GID) -t sbc-rock-2f/u-boot-builder -f $(DOCKERFILE_DIR)/Dockerfile.u-boot .
	sudo docker build --build-arg UID=$(UID) --build-arg GID=$(GID) -t sbc-rock-2f/kernel-builder -f $(DOCKERFILE_DIR)/Dockerfile.kernel .

u-boot:
	sudo docker run --rm -v $(shell pwd):/workspace sbc-rock-2f/u-boot-builder ./compile.sh u-boot

kernel:
	sudo docker run --rm -v $(shell pwd):/workspace sbc-rock-2f/kernel-builder ./compile.sh kernel

.DEFAULT_GOAL := error

error:
	@echo "Error: No target specified. Available targets are: builder, u-boot, kernel"
	exit 1

.PHONY: builder u-boot kernel error
