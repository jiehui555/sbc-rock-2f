#!/bin/bash

# Define Docker image name
IMAGE_NAME="rock-2f-uboot-builder"

# Error handling function
error_handler() {
    echo "❌ An error occurred!"
    echo "⚠️  Line number: $1"
    echo "📝 Command: $2"
    exit 1
}

# Cleanup function on script exit
cleanup() {
    echo "🧹 Cleaning up temporary files..."
}

# Set traps
trap 'error_handler $LINENO "$BASH_COMMAND"' ERR # Catch errors
trap cleanup EXIT                                # Execute cleanup on exit

# Exit immediately if a command exits with a non-zero status
set -e

# Step 1: Build the Docker image
echo "🚀 Building Docker image: $IMAGE_NAME ..."
sudo docker build -t "$IMAGE_NAME" .

# Step 2: Run the Docker container
echo "✅ Running Docker container..."
sudo docker run --rm -it --user $(id -u):$(id -g) -v $(pwd):/workspace "$IMAGE_NAME" bash
