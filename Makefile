IMAGE_NAME = sbc-rock-2f/u-boot-radxa-builder

.PHONY: builder build clean clean-all

builder:
	sudo docker build -t $(IMAGE_NAME) .

build:
	sudo docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		-v $(shell pwd):/workspace \
		$(IMAGE_NAME) ./build.sh

clean:
	sudo docker rmi -f $(IMAGE_NAME) || true
	echo "✅ Cleaned up Docker image: $(IMAGE_NAME)"

clean-all:
	rm -rf build/rkbin build/u-boot
	echo "🧹 Removed rkbin and u-boot directories but kept the toolchain."
