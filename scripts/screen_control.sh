#!/bin/sh
# ==============================================================================
# Script: screen_control.sh
# Purpose: Control HDMI Display Power (DPMS) to prevent TV burn-in and save energy
# ==============================================================================

ACTION="${1:-status}"

# Method 1: KMS DRM DPMS attribute path
DRM_DPMS="/sys/class/drm/card0-HDMI-A-1/dpms"

set_dpms_kms() {
    val="$1" # 0: On, 3: Off
    if [ -f "$DRM_DPMS" ]; then
        echo "$val" > "$DRM_DPMS" 2>/dev/null && return 0
    fi
    return 1
}

case "$ACTION" in
    on)
        echo "[ScreenControl] Turning HDMI Display ON..."
        if [ -f "/sys/devices/platform/mfds_ctrl/screen_power" ]; then
            echo 1 > "/sys/devices/platform/mfds_ctrl/screen_power" 2>/dev/null || true
        fi
        if command -v vcgencmd >/dev/null 2>&1; then
            vcgencmd display_power 1
        elif ! set_dpms_kms 0; then
            echo "[ScreenControl] Fallback: Waking virtual terminal..."
            echo -e "\033[9;0]" > /dev/tty1 2>/dev/null || true
        fi
        ;;
    off)
        echo "[ScreenControl] Turning HDMI Display OFF (Standby)..."
        if [ -f "/sys/devices/platform/mfds_ctrl/screen_power" ]; then
            echo 0 > "/sys/devices/platform/mfds_ctrl/screen_power" 2>/dev/null || true
        fi
        if command -v vcgencmd >/dev/null 2>&1; then
            vcgencmd display_power 0
        elif ! set_dpms_kms 3; then
            echo "[ScreenControl] Fallback: Blanking virtual terminal..."
            echo -e "\033[9;1]" > /dev/tty1 2>/dev/null || true
        fi
        ;;
    status)
        if [ -f "/sys/devices/platform/mfds_ctrl/screen_power" ]; then
            echo -n "MFDS Hardware Power: "
            cat "/sys/devices/platform/mfds_ctrl/screen_power"
        fi
        if command -v vcgencmd >/dev/null 2>&1; then
            vcgencmd display_power
        elif [ -f "$DRM_DPMS" ]; then
            cat "$DRM_DPMS"
        else
            echo "Display control interface not detected."
        fi
        ;;
    *)
        echo "Usage: $0 {on|off|status}"
        exit 1
        ;;
esac

exit 0
