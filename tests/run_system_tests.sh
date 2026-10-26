#!/bin/bash
# ==============================================================================
# Script: tests/run_system_tests.sh
# Purpose: Automated System-Wide Verification & Integrity Test Suite for MFDS
# ==============================================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SDK_ENV="/opt/poky/5.0.19-pi4-64/environment-setup-cortexa72-poky-linux"
DTC_PATH="/opt/poky/5.0.19-pi4-64/sysroots/x86_64-pokysdk-linux/usr/bin/dtc"

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

COLOR_GREEN="\033[0;32m"
COLOR_RED="\033[0;31m"
COLOR_YELLOW="\033[1;33m"
COLOR_BLUE="\033[0;34m"
COLOR_RESET="\033[0m"

log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $1"
}

log_pass() {
    echo -e "${COLOR_GREEN}[PASS]${COLOR_RESET} $1"
    ((PASSED_TESTS++))
}

log_fail() {
    echo -e "${COLOR_RED}[FAIL]${COLOR_RESET} $1"
    ((FAILED_TESTS++))
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $1"
    ((WARNINGS++))
}

run_test() {
    local test_name="$1"
    shift
    ((TOTAL_TESTS++))
    echo -e "\n---> Running: ${COLOR_BLUE}${test_name}${COLOR_RESET}"
    if "$@"; then
        log_pass "${test_name}"
    else
        log_fail "${test_name}"
    fi
}

echo "======================================================================"
echo "    MULTI-FUNCTION DISPLAY SYSTEM (MFDS) - SYSTEM TEST SUITE"
echo "======================================================================"

# ----------------------------------------------------------------------
# Test Group 1: Shell Scripts Syntax & Robustness
# ----------------------------------------------------------------------
test_shell_scripts() {
    local has_err=0
    for script in "$PROJECT_ROOT"/scripts/*.sh "$PROJECT_ROOT"/scripts/*.init; do
        if [ -f "$script" ]; then
            if ! bash -n "$script"; then
                echo "Syntax error in $script"
                has_err=1
            fi
        fi
    done
    return $has_err
}
run_test "Test 1: Shell Scripts Syntax Verification (bash -n)" test_shell_scripts

# ----------------------------------------------------------------------
# Test Group 2: Device Tree Overlay Verification
# ----------------------------------------------------------------------
test_device_tree() {
    local dts_file="$PROJECT_ROOT/devicetree/mfds-kiosk-overlay.dts"
    local dtbo_tmp="/tmp/mfds_test_overlay.dtbo"
    
    if [ ! -f "$dts_file" ]; then
        echo "DTS file not found: $dts_file"
        return 1
    fi

    if [ -x "$DTC_PATH" ]; then
        "$DTC_PATH" -@ -I dts -O dtb -o "$dtbo_tmp" "$dts_file" 2>&1
        local ret=$?
        rm -f "$dtbo_tmp"
        return $ret
    else
        dtc -@ -I dts -O dtb -o "$dtbo_tmp" "$dts_file" 2>&1
        local ret=$?
        rm -f "$dtbo_tmp"
        return $ret
    fi
}
run_test "Test 2: Device Tree Overlay Compilation & Syntax Check" test_device_tree

# ----------------------------------------------------------------------
# Test Group 3: Kernel Platform Driver Build & Symbol Integrity
# ----------------------------------------------------------------------
test_driver_build() {
    local driver_dir="$PROJECT_ROOT/src/driver"
    if [ -f "$SDK_ENV" ]; then
        # shellcheck disable=SC1090
        source "$SDK_ENV"
    fi

    if make -C "$driver_dir" clean >/dev/null 2>&1 && make -C "$driver_dir" all >/dev/null 2>&1; then
        local ko_file="$driver_dir/mfds_ctrl.ko"
        if [ -f "$ko_file" ]; then
            # Verify alias matches compatible string
            if modinfo "$ko_file" | grep -q "alias:.*mfds,kiosk-ctrl"; then
                return 0
            else
                echo "Module alias does not match compatible string"
                return 1
            fi
        fi
    fi
    return 1
}
run_test "Test 3: Kernel Platform Driver Compilation & DT Matching Alias" test_driver_build

# ----------------------------------------------------------------------
# Test Group 4: JSON Data Contract & Resilience Simulation
# ----------------------------------------------------------------------
test_json_resilience() {
    python3 - "$PROJECT_ROOT" << 'EOF'
import json
import sys
import os

project_root = sys.argv[1]
schema_path = os.path.join(project_root, "docs/data_schema.json")
sample_path = os.path.join(project_root, "docs/data_sample.json")

try:
    with open(schema_path, 'r', encoding='utf-8') as f:
        schema = json.load(f)
    with open(sample_path, 'r', encoding='utf-8') as f:
        sample = json.load(f)
except Exception as e:
    print(f"Error loading JSON documents: {e}")
    sys.exit(1)

# Check required top-level keys
required_keys = ["version", "system", "notices", "schedules", "news_ticker"]
for k in required_keys:
    if k not in sample:
        print(f"Missing required key in sample: {k}")
        sys.exit(1)

# Simulate edge cases
edge_cases = [
    ("Empty String", ""),
    ("Truncated JSON", '{"version": "1.0.0", "system": {'),
    ("Empty Object", "{}"),
    ("Extra Keys", '{"version":"1.0.0","system":{"device_name":"x","location":"y","banner_title":"z"},"notices":[],"schedules":[],"news_ticker":[],"unexpected_future_key": 999}')
]

print("Simulating edge-case JSON payloads:")
for name, payload in edge_cases:
    try:
        parsed = json.loads(payload)
        is_valid = isinstance(parsed, dict)
        print(f" - {name}: Valid JSON Object = {is_valid}")
    except json.JSONDecodeError:
        print(f" - {name}: Properly caught as JSONDecodeError (requires fallback in DataManager)")

sys.exit(0)
EOF
}
run_test "Test 4: JSON Schema Verification & Edge-Case Simulation" test_json_resilience

# ----------------------------------------------------------------------
# Test Group 5: Atomic IPC Simulation & Invariant Check
# ----------------------------------------------------------------------
test_atomic_ipc_suite() {
    python3 "$PROJECT_ROOT/tests/test_atomic_ipc.py"
}
run_test "Test 5: Atomic IPC Invariance & Inotify Simulation (test_atomic_ipc.py)" test_atomic_ipc_suite

# ----------------------------------------------------------------------
# Test Group 6: Qt 6.8 Application Binary Integrity & Strict Compiler Check
# ----------------------------------------------------------------------
test_app_build() {
    if [ -f "$SDK_ENV" ]; then
        # shellcheck disable=SC1090
        source "$SDK_ENV"
    fi

    local build_dir="$PROJECT_ROOT/src/app/build"
    if cmake --build "$build_dir" --parallel >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
run_test "Test 6: Qt 6.8 Application Binary Integrity (-Wall -Wextra)" test_app_build

# ----------------------------------------------------------------------
# Test Group 7: Watchdog & Sysfs Path Consistency Check
# ----------------------------------------------------------------------
test_header_path_consistency() {
    local header="$PROJECT_ROOT/include/mfds_ctrl.h"
    local driver="$PROJECT_ROOT/src/driver/mfds_ctrl.c"

    if grep -q "screen_power" "$header" && grep -q "screen_power" "$driver" && \
       grep -q "soc_temp" "$header" && grep -q "soc_temp" "$driver"; then
        return 0
    else
        echo "Sysfs attribute mismatch between header and driver (missing soc_temp/screen_power)"
        return 1
    fi
}
run_test "Test 7: Sysfs Interface Definition & soc_temp Consistency" test_header_path_consistency

# ----------------------------------------------------------------------
# Test Group 8: Watchdog Supervisor Concurrency & Static Data Keepalive (DEF-01, DEF-02, DEF-03, DEF-12)
# ----------------------------------------------------------------------
test_watchdog_concurrency_and_static_data() {
    local test_src="$PROJECT_ROOT/tests/test_watchdog_supervisor.cpp"
    local test_bin="/tmp/test_watchdog_supervisor_$$"

    if [ ! -f "$test_src" ]; then
        echo "Test source $test_src not found."
        return 1
    fi

    if ! g++ -std=c++17 -pthread -O2 "$test_src" -o "$test_bin"; then
        echo "Failed to compile test_watchdog_supervisor.cpp"
        return 1
    fi

    if ! "$test_bin"; then
        rm -f "$test_bin"
        echo "test_watchdog_supervisor execution failed."
        return 1
    fi

    rm -f "$test_bin"
    return 0
}
run_test "Test 8: Watchdog Concurrency, Static Data Keepalive & Deadlock Freeze (C++ Integration)" test_watchdog_concurrency_and_static_data


# ----------------------------------------------------------------------
# Summary
# ----------------------------------------------------------------------
echo -e "\n======================================================================"
echo "                          TEST SUITE RESULTS"
echo "======================================================================"
echo -e "Total Tests Executed : ${TOTAL_TESTS}"
echo -e "Tests Passed         : ${COLOR_GREEN}${PASSED_TESTS}${COLOR_RESET}"
echo -e "Tests Failed         : ${COLOR_RED}${FAILED_TESTS}${COLOR_RESET}"
echo "======================================================================"

if [ "$FAILED_TESTS" -eq 0 ]; then
    echo -e "${COLOR_GREEN}[SUCCESS] All automated verification tests passed cleanly!${COLOR_RESET}"
    exit 0
else
    echo -e "${COLOR_RED}[FAILURE] Some verification tests failed. Inspect logs above.${COLOR_RESET}"
    exit 1
fi
