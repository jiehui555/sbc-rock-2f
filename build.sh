#!/bin/bash

# Define Docker image name
IMAGE_NAME="rock-2f-uboot-builder"

# Create logs directory if it doesn't exist
LOG_DIR="./logs"
mkdir -p "$LOG_DIR"

# Generate log file with timestamp
LOG_FILE="$LOG_DIR/build_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Redirect all script output to the log file while still showing it in the terminal
exec > >(tee -a "$LOG_FILE") 2>&1

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
sudo docker run --rm --user $(id -u):$(id -g) -v $(pwd)/u-boot:/workspace/u-boot -v $(pwd)/rkbin:/workspace/rkbin "$IMAGE_NAME" bash -c "
    # Change directory to u-boot
    cd u-boot
    echo '✅ Inside Docker container...'

    # Build U-Boot for Rock-2F
    ./make.sh rock-2-rk3528
    echo '✅ U-Boot build completed for rock-2-rk3528'

    # Build the bootloader
    ./make.sh loader
    echo '✅ Bootloader build completed'

    # Generate the ITB (Image Tree Blob)
    ./make.sh itb
    echo '✅ ITB build completed'
"

# Step 3: Validate output files
echo "🔍 Checking generated files..."
if [[ ! -f "./rkbin/idblock.img" ]]; then
    echo "⚠️ Warning: Missing file ./rkbin/idblock.img"
    exit 1
fi

if [[ ! -f "./u-boot/u-boot.itb" ]]; then
    echo "⚠️ Warning: Missing file ./u-boot/u-boot.itb"
    exit 1
fi

echo "✅ Required files found!"

# Step 4: Check if 'output' folder exists
OUTPUT_DIR="./output"
if [[ -d "$OUTPUT_DIR" ]]; then
    read -p "⚠️ The output folder already exists. Do you want to delete it? (y/n): " choice
    case "$choice" in
    y | Y)
        echo "🗑 Deleting output folder..."
        rm -rf "$OUTPUT_DIR"
        ;;
    n | N) echo "⚠️ Keeping existing output folder. Files may be overwritten." ;;
    *)
        echo "❌ Invalid input. Exiting."
        exit 1
        ;;
    esac
fi

# Step 5: Create output folder and copy generated files
echo "📁 Creating output directory..."
mkdir -p "$OUTPUT_DIR"

echo "📄 Copying generated files..."
cp ./rkbin/idblock.img "$OUTPUT_DIR/"
cp ./u-boot/u-boot.itb "$OUTPUT_DIR/"

echo "✅ Build process completed successfully!"
echo "📜 Log saved to: $LOG_FILE"
