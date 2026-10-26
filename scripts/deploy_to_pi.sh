#!/bin/bash
# ==============================================================================
# Script: deploy_to_pi.sh
# Purpose: Auto-build, transfer, activate driver/overlay, and execute MFDS on Raspberry Pi 4
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

# 1. Compile application & kernel driver artifacts
echo "[Step 1/4] Compiling application and kernel platform driver..."
"$BUILD_SCRIPT"
"$PROJECT_ROOT/scripts/build_driver.sh"

# 2. Transfer artifacts to Pi 4
echo "[Step 2/4] Transferring artifacts to $TARGET_USER@$TARGET_IP:$REMOTE_DIR..."
ssh -o BatchMode=yes -o ConnectTimeout=5 "$TARGET_USER@$TARGET_IP" "mkdir -p $REMOTE_DIR /boot/overlays /boot/firmware/overlays"
scp -q "$BINARY_LOCAL" "$TARGET_USER@$TARGET_IP:$REMOTE_DIR/appMultiFunctionDisplay"
scp -q "$PROJECT_ROOT/src/driver/mfds_ctrl.ko" "$TARGET_USER@$TARGET_IP:$REMOTE_DIR/mfds_ctrl.ko"
scp -q "$PROJECT_ROOT/devicetree/mfds-kiosk-overlay.dtbo" "$TARGET_USER@$TARGET_IP:$REMOTE_DIR/mfds-kiosk-overlay.dtbo"
scp -q "$PROJECT_ROOT/scripts/mfds-kiosk.init" "$TARGET_USER@$TARGET_IP:/etc/init.d/mfds-kiosk"
scp -q "$PROJECT_ROOT/docs/data_sample.json" "$TARGET_USER@$TARGET_IP:$REMOTE_DIR/data_sample.json"

# 3. DEF-05: Activate Device Tree Overlay and insert Kernel Platform Driver
echo "[Step 3/4] Activating Device Tree overlay and inserting kernel driver..."
ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" bash -c "'
    chmod +x $REMOTE_DIR/appMultiFunctionDisplay /etc/init.d/mfds-kiosk
    
    # 3a. Install and activate Device Tree Overlay
    cp -f $REMOTE_DIR/mfds-kiosk-overlay.dtbo /boot/overlays/ 2>/dev/null || true
    cp -f $REMOTE_DIR/mfds-kiosk-overlay.dtbo /boot/firmware/overlays/ 2>/dev/null || true
    dtoverlay mfds-kiosk-overlay 2>/dev/null || dtoverlay -d /boot/overlays mfds-kiosk-overlay 2>/dev/null || true
    
    # Persist in config.txt if not already set
    for cfg in /boot/firmware/config.txt /boot/config.txt; do
        if [ -f \"\$cfg\" ] && ! grep -q \"^dtoverlay=mfds-kiosk-overlay\" \"\$cfg\"; then
            echo \"dtoverlay=mfds-kiosk-overlay\" >> \"\$cfg\"
        fi
    done

    # 3b. Load kernel platform driver
    rmmod mfds_ctrl 2>/dev/null || true
    insmod $REMOTE_DIR/mfds_ctrl.ko 2>/dev/null || modprobe mfds_ctrl 2>/dev/null || true

    # Verify sysfs presence
    if [ -d /sys/devices/platform/mfds_ctrl ]; then
        echo \"[SUCCESS] mfds_ctrl kernel driver active and probed at /sys/devices/platform/mfds_ctrl\"
    else
        echo \"[WARNING] /sys/devices/platform/mfds_ctrl not yet probed (requires reboot if overlay newly registered)\"
    fi
'"

# 4. Launch application on target
echo "[Step 4/4] Launching application on target..."
if [ "$MODE" == "--eglfs" ] || [ "$MODE" == "--service" ]; then
    echo "[INFO] Starting via /etc/init.d/mfds-kiosk service (native EGLFS KMS/DRM)..."
    ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "/etc/init.d/mfds-kiosk restart"
else
    echo "[INFO] Running in interactive VNC mode (1920x1080 @ port 5900)..."
    ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" bash -c "'
        if [ -x /etc/init.d/mfds-kiosk ]; then
            /etc/init.d/mfds-kiosk stop 2>/dev/null || true
        else
            killall appMultiFunctionDisplay 2>/dev/null || true
        fi
        mkdir -p /var/lib/mfds
        if [ ! -f /var/lib/mfds/data.json ] && [ -f $REMOTE_DIR/data_sample.json ]; then
            cp $REMOTE_DIR/data_sample.json /var/lib/mfds/data.json
        fi
        cd $REMOTE_DIR
        nohup $REMOTE_DIR/appMultiFunctionDisplay -platform vnc:size=1920x1080:port=5900 >/tmp/mfds.log 2>&1 &
        sleep 1
    '"
fi

# 5. Check status
echo "=========================================================="
ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "cat /tmp/mfds.log 2>/dev/null | head -n 10 || true"
if ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "pgrep -f appMultiFunctionDisplay >/dev/null"; then
    echo "[SUCCESS] MultiFunctionDisplay is RUNNING on Pi 4!"
    if [ "$MODE" == "--vnc" ]; then
        echo ">>> Connect with Remmina VNC: $TARGET_IP:5900"
    fi
else
    echo "[WARNING] Process did not stay running. Check /tmp/mfds.log or /var/log/mfds-kiosk.log on Pi 4."
fi
echo "=========================================================="

