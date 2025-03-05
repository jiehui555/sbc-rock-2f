IMAGE_NAME = sbc-rock-2f/radxa-kernel-builder
UID := $(shell id -u)
GID := $(shell id -g)

.PHONY: builder build clean

builder:
	sudo docker build --build-arg UID=$(UID) --build-arg GID=$(GID) -t $(IMAGE_NAME) .

build:
	sudo docker run --rm -it -v $(shell pwd):/workspace $(IMAGE_NAME) bash

clean:
	rm -rf build
