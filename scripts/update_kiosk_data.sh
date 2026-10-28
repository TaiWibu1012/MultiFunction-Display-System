#!/bin/bash
# ==============================================================================
# Script: update_kiosk_data.sh
# Purpose: Demonstrate real-time atomic data update on Raspberry Pi 4 kiosk
# Note: Performs JSON processing on host and uses atomic rename on target
# ==============================================================================

set -e

TARGET_IP="${1:-100.76.193.127}"
TARGET_USER="root"
CUSTOM_NOTICE_TITLE="${2:-CẬP NHẬT TRẠNG THÁI THỜI GIAN THỰC}"
CUSTOM_NOTICE_CONTENT="${3:-Đã nhận tín hiệu đồng bộ qua IPC Inotify lúc $(date '+%H:%M:%S'). Hệ thống phản hồi tức thì mà không cần khởi động lại.}"

echo "=========================================================="
echo " Pushing Real-Time Atomic Data Update to Pi 4 ($TARGET_IP) "
echo "=========================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMP_JSON="/tmp/mfds_live_update.json"
CURRENT_TIME=$(date '+%H:%M:%S')
CURRENT_DATE=$(date '+%Y-%m-%d')

# 1. Fetch current data or use local template
scp -q -o ConnectTimeout=5 "$TARGET_USER@$TARGET_IP:/var/lib/mfds/data.json" "$TEMP_JSON" 2>/dev/null || \
    cp "$PROJECT_ROOT/docs/data_sample.json" "$TEMP_JSON"

# 2. Modify payload locally using python3
python3 - "$TEMP_JSON" "$CUSTOM_NOTICE_TITLE" "$CUSTOM_NOTICE_CONTENT" "$CURRENT_TIME" "$CURRENT_DATE" << 'EOF'
import sys
import json

json_file = sys.argv[1]
title = sys.argv[2]
content = sys.argv[3]
time_str = sys.argv[4]
date_str = sys.argv[5]

try:
    with open(json_file, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    data = {}

# Prepend new notice
notices = data.get("notices", [])
new_notice = {
    "id": 99,
    "title": title,
    "content": content,
    "priority": "update",
    "date": date_str,
    "active": True
}
data["notices"] = [new_notice] + notices[:2]

# Update news ticker with live timestamp
ticker = data.get("news_ticker", [])
ticker_live = f"● LIVE UPDATE [{time_str}]: ĐỒNG BỘ DỮ LIỆU THÀNH CÔNG QUA INOTIFY ATOMIC IPC"
data["news_ticker"] = [ticker_live] + ticker[:2]

with open(json_file, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
EOF

# 3. Transfer atomically to target per atomic-ipc-guard skill
scp -q "$TEMP_JSON" "$TARGET_USER@$TARGET_IP:/var/lib/mfds/data.json.tmp"
ssh -o BatchMode=yes "$TARGET_USER@$TARGET_IP" "sync && mv -f /var/lib/mfds/data.json.tmp /var/lib/mfds/data.json"
rm -f "$TEMP_JSON"

echo "=========================================================="
echo "[SUCCESS] Real-time data pushed at $CURRENT_TIME! Check your physical screen."
echo "=========================================================="
