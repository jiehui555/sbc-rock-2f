#!/bin/bash

# Set working directory inside the container
WORKSPACE_DIR="/workspace"

# Ensure script runs in the correct directory
cd "$WORKSPACE_DIR" || exit 1

# Create logs directory if it doesn't exist
LOG_DIR="$WORKSPACE_DIR/logs"
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

# Step 1: Change directory to u-boot
echo "✅ Inside Docker container..."
cd u-boot

# Step 2: Build U-Boot for Rock-2F
echo "🚀 Building U-Boot for Rock-2F..."
./make.sh rock-2-rk3528
echo "✅ U-Boot build completed for rock-2-rk3528"

# Step 3: Build the bootloader
echo "🔧 Building bootloader..."
./make.sh loader
echo "✅ Bootloader build completed"

# Step 4: Generate the ITB (Image Tree Blob)
echo "🛠 Generating ITB..."
./make.sh itb
echo "✅ ITB build completed"

# Step 5: Validate output files
echo "🔍 Checking generated files..."
if [[ ! -f "$WORKSPACE_DIR/rkbin/idblock.img" ]]; then
    echo "⚠️ Warning: Missing file $WORKSPACE_DIR/rkbin/idblock.img"
    exit 1
fi

if [[ ! -f "$WORKSPACE_DIR/u-boot/u-boot.itb" ]]; then
    echo "⚠️ Warning: Missing file $WORKSPACE_DIR/u-boot/u-boot.itb"
    exit 1
fi

echo "✅ Required files found!"

# Step 6: Check if 'output' folder exists
OUTPUT_DIR="$WORKSPACE_DIR/output"
if [[ -d "$OUTPUT_DIR" ]]; then
    echo "⚠️ The output folder already exists. Deleting it..."
    rm -rf "$OUTPUT_DIR"
fi

# Step 7: Create output folder and copy generated files
echo "📁 Creating output directory..."
mkdir -p "$OUTPUT_DIR"

echo "📄 Copying generated files..."
cp "$WORKSPACE_DIR/rkbin/idblock.img" "$OUTPUT_DIR/"
cp "$WORKSPACE_DIR/u-boot/u-boot.itb" "$OUTPUT_DIR/"

echo "✅ Build process completed successfully!"
echo "📜 Log saved to: $LOG_FILE"
