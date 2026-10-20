#!/bin/bash
# ==============================================================================
# Script: deploy_to_pi.sh
# Purpose: Auto-build, transfer, and execute MultiFunctionDisplay on Raspberry Pi 4
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_SCRIPT="$SCRIPT_DIR/build_app.sh"
BINARY_LOCAL="$PROJECT_ROOT/src/app/build/appMultiFunctionDisplay"

TARGET_IP="${1:-100.76.193.127}"
TARGET_USER="root"
REMOTE_DIR="/home/root/mfds"
MODE="${2:---vnc}"

echo "=========================================================="
echo " Deploying MultiFunctionDisplay to Pi 4 ($TARGET_IP) "
echo "=========================================================="

# 1. Compile the application
echo "[Step 1/3] Compiling application..."
"$BUILD_SCRIPT"

# 2. Transfer binary to Pi 4
echo "[Step 2/3] Transferring binary to $TARGET_USER@$TARGET_IP:$REMOTE_DIR..."
ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_USER@$TARGET_IP" "mkdir -p $REMOTE_DIR"
scp -q "$BINARY_LOCAL" "$TARGET_USER@$TARGET_IP:$REMOTE_DIR/appMultiFunctionDisplay"
ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "chmod +x $REMOTE_DIR/appMultiFunctionDisplay"

# 3. Launch application on target
echo "[Step 3/3] Launching application on target..."
ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "killall -9 appMultiFunctionDisplay 2>/dev/null || true"

if [ "$MODE" == "--eglfs" ]; then
    echo "[INFO] Running in native EGLFS KMS/DRM mode (Direct HDMI)..."
    ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "nohup $REMOTE_DIR/appMultiFunctionDisplay -platform eglfs >/tmp/mfds.log 2>&1 & sleep 1"
else
    echo "[INFO] Running in VNC mode (1920x1080 @ port 5900)..."
    ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "nohup $REMOTE_DIR/appMultiFunctionDisplay -platform vnc:size=1920x1080:port=5900 >/tmp/mfds.log 2>&1 & sleep 1"
fi

# 4. Check status
echo "=========================================================="
ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "cat /tmp/mfds.log 2>/dev/null | head -n 10 || true"
if ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "pgrep -f appMultiFunctionDisplay >/dev/null"; then
    echo "[SUCCESS] MultiFunctionDisplay is RUNNING on Pi 4!"
    if [ "$MODE" != "--eglfs" ]; then
        echo ">>> Connect with Remmina VNC: $TARGET_IP:5900"
    fi
else
    echo "[WARNING] Process did not stay running. Check /tmp/mfds.log on Pi 4."
fi
echo "=========================================================="
