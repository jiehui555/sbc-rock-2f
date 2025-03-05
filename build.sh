#!/bin/bash

# Set working directory inside the container
WORKSPACE_DIR="/workspace"

# Ensure script runs in the correct directory
cd "$WORKSPACE_DIR" || exit 1

# Create build directory
BUILD_DIR="$WORKSPACE_DIR/build"
if [[ -d "$BUILD_DIR" ]]; then
    echo "⚠️ Build directory already exists. Please ensure it's clean before proceeding."
else
    mkdir -p "$BUILD_DIR"
fi

# Create logs directory if it doesn't exist
LOG_DIR="$BUILD_DIR/logs"
mkdir -p "$LOG_DIR"

# Generate log file with timestamp
LOG_FILE="$LOG_DIR/build_$(date '+%Y-%m-%d_%H-%M-%S').log"

# Redirect all script output to the log file while still showing it in the terminal
exec > >(tee -a "$LOG_FILE") 2>&1

# Error handling function
error_handler() {
    echo "❌ An error occurred!"
    echo "⚠️ Line number: $1"
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

# Step 1: Clone repositories and prepare environment
echo "✅ Preparing build environment..."
cd "$BUILD_DIR"

# Download Kernel library
if [[ ! -d "kernel" ]]; then
    echo "📥 Cloning Kernel repository..."
    git clone --depth=1 --branch=linux-6.1-stan-rkr4.1 https://github.com/radxa/kernel.git && echo "✅ Kernel repository successfully cloned."
else
    echo "⚠️ Kernel repository already exists. Skipping clone."
fi

# Apply overlay modifications
OVERLAY_DIR="$WORKSPACE_DIR/overlay"
if [[ -d "$OVERLAY_DIR" ]]; then
    echo "🔄 Applying overlay modifications..."
    cp -rT "$OVERLAY_DIR" "$BUILD_DIR/"
    echo "✅ Overlay applied successfully."
else
    echo "⚠️ No overlay directory found. Skipping overlay application."
fi

# Step 2: Build Kernel for Rock-2F
echo "🚀 Building U-BKernel for Rock-2F..."
cd "$BUILD_DIR/kernel"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- rockchip_linux_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)

# Step 3: Validate output files
echo "🔍 Checking generated files..."

REQUIRED_FILES=(
    "$BUILD_DIR/kernel/arch/arm64/boot/Image.gz"
    "$BUILD_DIR/kernel/arch/arm64/boot/dts/rockchip/rk3528-rock-2f.dtb"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "⚠️ Warning: Missing file $file"
        exit 1
    fi
done

echo "✅ All required files found!"

# Step 6: Prepare output folder
OUTPUT_DIR="$WORKSPACE_DIR/output"
if [[ -d "$OUTPUT_DIR" ]]; then
    echo "⚠️ The output folder already exists. Deleting it..."
    rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"

# Step 7: Copy generated files
echo "📄 Copying generated files to output directory..."
cp "$BUILD_DIR/kernel/arch/arm64/boot/Image.gz" "$OUTPUT_DIR/"
cp "$BUILD_DIR/kernel/arch/arm64/boot/dts/rockchip/rk3528-rock-2f.dtb" "$OUTPUT_DIR/"

echo "✅ Build process completed successfully!"
echo "📜 Log saved to: $LOG_FILE"
