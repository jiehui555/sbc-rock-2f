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

# Download rkbin library
if [[ ! -d "rkbin" ]]; then
    echo "📥 Cloning rkbin repository..."
    git clone --depth=1 --branch=master https://github.com/rockchip-linux/rkbin && echo "✅ rkbin repository successfully cloned."
else
    echo "⚠️ rkbin repository already exists. Skipping clone."
fi

# Download U-Boot library
if [[ ! -d "u-boot" ]]; then
    echo "📥 Cloning U-Boot repository..."
    git clone --depth=1 --branch=next-dev-v2024.10 https://github.com/radxa/u-boot && echo "✅ U-Boot repository successfully cloned."
else
    echo "⚠️ U-Boot repository already exists. Skipping clone."
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

# Download cross-compile toolchain
TOOLCHAIN_DIR="$BUILD_DIR/prebuilts/gcc/linux-x86/aarch64"
mkdir -p "$TOOLCHAIN_DIR"
TOOLCHAIN_URL="https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz"
TOOLCHAIN_ARCHIVE="$(basename "$TOOLCHAIN_URL")"

if [[ ! -d "$TOOLCHAIN_DIR/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu" ]]; then
    echo "📥 Downloading cross-compile toolchain..."
    wget "$TOOLCHAIN_URL" -O "$TOOLCHAIN_ARCHIVE" && echo "✅ Cross-compile toolchain successfully downloaded."
    tar xf "$TOOLCHAIN_ARCHIVE" -C "$TOOLCHAIN_DIR"
    rm "$TOOLCHAIN_ARCHIVE"
else
    echo "⚠️ Cross-compile toolchain already exists. Skipping download."
fi

# Step 2: Build U-Boot for Rock-2F
echo "🚀 Building U-Boot for Rock-2F..."
cd "$BUILD_DIR/u-boot"
./make.sh rock-2-rk3528

# Step 3: Build the bootloader
echo "🔧 Building bootloader..."
./make.sh loader

# Step 4: Generate the ITB (Image Tree Blob)
echo "🛠 Generating ITB..."
./make.sh itb

# Step 5: Validate output files
echo "🔍 Checking generated files..."
REQUIRED_FILES=(
    "$BUILD_DIR/rkbin/idblock.img"
    "$BUILD_DIR/u-boot/u-boot.itb"
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
cp "$BUILD_DIR/rkbin/idblock.img" "$OUTPUT_DIR/"
cp "$BUILD_DIR/u-boot/u-boot.itb" "$OUTPUT_DIR/"

echo "✅ Build process completed successfully!"
echo "📜 Log saved to: $LOG_FILE"
