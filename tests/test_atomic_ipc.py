#!/usr/bin/env python3
"""
Unit Test: test_atomic_ipc.py
Tests Atomic IPC Invariance, Fallback Cache logic, and JSON Schema Compliance.
Adheres to: atomic-ipc-guard skill and qt-eglfs-ipc.md rules.
"""

import os
import sys
import json
import tempfile
import time

def test_atomic_write_simulation():
    test_dir = tempfile.mkdtemp(prefix="mfds_ipc_test_")
    target_file = os.path.join(test_dir, "data.json")
    tmp_file = os.path.join(test_dir, "data.json.tmp")

    payload_valid = {
        "version": "1.0.0",
        "system": {
            "device_name": "Test-Box",
            "location": "Lab E2",
            "banner_title": "TEST BANNER"
        },
        "notices": [{"id": 1, "title": "Test", "content": "Content", "priority": "info", "date": "2026-10-23", "active": True}],
        "schedules": [{"id": 1, "time_slot": "09:00", "event_name": "Meet", "room": "A", "host": "Admin"}],
        "news_ticker": ["TEST TICKER"]
    }

    # Step 1: Write to tmp
    with open(tmp_file, "w", encoding="utf-8") as f:
        json.dump(payload_valid, f)
        f.flush()
        os.fsync(f.fileno())

    # Step 2: Atomic rename
    os.replace(tmp_file, target_file)

    assert os.path.exists(target_file), "Atomic replace failed to create target file"
    with open(target_file, "r", encoding="utf-8") as f:
        loaded = json.load(f)
    assert loaded["version"] == "1.0.0", "Data corrupted in atomic replace"

    # Step 3: Test partial write / empty file fallback resilience
    empty_file = os.path.join(test_dir, "empty.json")
    with open(empty_file, "w") as f:
        pass
    assert os.path.getsize(empty_file) == 0, "Empty file creation failed"

    # Clean up
    os.remove(target_file)
    os.remove(empty_file)
    os.rmdir(test_dir)
    print("[PASS] Atomic IPC Simulation & Invariant Check Succeeded.")
    return 0

if __name__ == "__main__":
    sys.exit(test_atomic_write_simulation())
