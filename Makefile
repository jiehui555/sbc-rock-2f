IMAGE_NAME = sbc-rock-2f/u-boot-radxa-builder

build-docker-image:
	sudo docker build -t $(IMAGE_NAME) .

build:
	sudo docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		-v $(shell pwd):/workspace \
		$(IMAGE_NAME) ./build.sh
