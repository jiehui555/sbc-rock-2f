#!/bin/bash

# Function to print log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Get parameters from the main script
WORKSPACE_DIR=$1
BUILD_DIR=$2
LOG_FILE=$3

# Step 1: Clone repositories and prepare environment
log "✅ Preparing Kernel build environment..."
cd "$BUILD_DIR"

# Download Kernel library
if [[ ! -d "kernel" ]]; then
    log "📥 Cloning Kernel repository..."
    git clone --depth=1 --branch=linux-6.1-stan-rkr4.1 https://github.com/radxa/kernel.git && log "✅ Kernel repository successfully cloned."
else
    log "⚠️ Kernel repository already exists. Skipping clone."
fi

# Apply overlay modifications
OVERLAY_DIR="$WORKSPACE_DIR/overlay"
if [[ -d "$OVERLAY_DIR" ]]; then
    log "🔄 Applying overlay modifications..."
    cp -rT "$OVERLAY_DIR" "$BUILD_DIR/"
    log "✅ Overlay applied successfully."
else
    log "⚠️ No overlay directory found. Skipping overlay application."
fi

# Step 2: Build Kernel for Rock-2F
log "🚀 Building U-BKernel for Rock-2F..."
cd "$BUILD_DIR/kernel"
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- rockchip_linux_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
log "✅ Kernel build completed."

# Step 3: Validate output files
log "🔍 Checking generated files..."

REQUIRED_FILES=(
    "$BUILD_DIR/kernel/arch/arm64/boot/Image.gz"
    "$BUILD_DIR/kernel/arch/arm64/boot/dts/rockchip/rk3528-rock-2f.dtb"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        log "⚠️ Warning: Missing file $file"
        exit 1
    fi
done

log "✅ All required files found!"

# Step 4: Prepare output folder
OUTPUT_DIR="$WORKSPACE_DIR/output/kernel"
if [[ -d "$OUTPUT_DIR" ]]; then
    log "⚠️ The output folder already exists. Deleting it..."
    rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"
log "📁 Created output directory."

# Step 5: Copy generated files
log "📄 Copying generated files to output directory..."
cp "$BUILD_DIR/kernel/arch/arm64/boot/Image.gz" "$OUTPUT_DIR/"
cp "$BUILD_DIR/kernel/arch/arm64/boot/dts/rockchip/rk3528-rock-2f.dtb" "$OUTPUT_DIR/"

log "✅ Kernel build process completed successfully!"
