#!/bin/bash
# ==============================================================================
# Script: build_driver.sh
# Purpose: Cross-compile MFDS Kiosk Driver & Device Tree Overlay (ARM64)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_ENV="/opt/poky/5.0.19-pi4-64/environment-setup-cortexa72-poky-linux"
DRIVER_DIR="$PROJECT_ROOT/src/driver"

echo "=========================================================="
echo " Building MFDS Kiosk Driver & Device Tree Overlay "
echo "=========================================================="

if [ -f "$SDK_ENV" ]; then
    echo "[INFO] Sourcing Yocto SDK environment: $SDK_ENV"
    # shellcheck disable=SC1090
    source "$SDK_ENV"
fi

echo "[INFO] Compiling kernel module and DTBO in $DRIVER_DIR..."
make -C "$DRIVER_DIR" all

echo "=========================================================="
echo "[SUCCESS] Build artifacts ready:"
echo " - Module:  $DRIVER_DIR/mfds_ctrl.ko"
echo " - Overlay: $PROJECT_ROOT/devicetree/mfds-kiosk-overlay.dtbo"
echo "=========================================================="
