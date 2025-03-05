IMAGE_NAME = sbc-rock-2f/radxa-u-boot-builder

.PHONY: builder build clean clean-all

builder:
	sudo docker build -t $(IMAGE_NAME) .

build:
	sudo docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		-v $(shell pwd):/workspace \
		$(IMAGE_NAME) ./build.sh

clean:
	rm -rf build
