#!/bin/bash
# ==============================================================================
# Script: build_app.sh
# Purpose: Cross-compile Qt 6.8 Dashboard Application for Raspberry Pi 4 (64-bit)
# ==============================================================================

set -e

SDK_ENV="/opt/poky/5.0.19-pi4-64/environment-setup-cortexa72-poky-linux"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$PROJECT_ROOT/src/app"
BUILD_DIR="$APP_DIR/build"

# Check if SDK environment is sourced
if [ -z "$OECORE_TARGET_SYSROOT" ]; then
    if [ -f "$SDK_ENV" ]; then
        echo "[INFO] Sourcing Yocto SDK environment..."
        # shellcheck disable=SC1090
        source "$SDK_ENV"
    else
        echo "[ERROR] SDK environment not found at $SDK_ENV"
        exit 1
    fi
fi

echo "=========================================================="
echo " Building MultiFunctionDisplay (ARM64 Cortex-A72) "
echo "=========================================================="

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "[1/2] Configuring CMake with Qt6 Toolchain..."
qt-cmake -B "$BUILD_DIR" -S "$APP_DIR" -G Ninja -DCMAKE_BUILD_TYPE=Release

echo "[2/2] Compiling with Ninja..."
cmake --build "$BUILD_DIR" --parallel

echo "=========================================================="
echo "[SUCCESS] Binary created: $BUILD_DIR/appMultiFunctionDisplay"
echo "=========================================================="
