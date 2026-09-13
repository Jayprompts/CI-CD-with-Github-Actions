#!/usr/bin/env bash
#
# test.sh
# Assignment 3 - CI/CD with GitHub Actions
#
# Tests for app/app.sh covering: help, system-info, invalid commands,
# missing host, a valid host, missing port, non-numeric port, and
# out-of-range ports.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="${SCRIPT_DIR}/../app/app.sh"

PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

assert_exit() {
    local desc="$1"
    local expected="$2"
    shift 2
    "$APP" "$@" >/tmp/assignment3-test-out.log 2>&1
    local actual=$?
    if [[ "$actual" -eq "$expected" ]]; then
        pass "$desc (exit $actual)"
    else
        fail "$desc (expected exit $expected, got $actual)"
        cat /tmp/assignment3-test-out.log
    fi
}

echo "===================================="
echo " Assignment 3 - app.sh Test Suite"
echo "===================================="

# 1. help
assert_exit "help command succeeds" 0 help

# 2. system-info
assert_exit "system-info command succeeds" 0 system-info

# 3. invalid command
assert_exit "unknown command returns exit code 2" 2 bogus-command

# 4. missing command entirely
assert_exit "missing command returns exit code 2" 2

# 5. missing host (check-host with no argument)
assert_exit "check-host with missing host returns exit code 2" 2 check-host

# 6. a valid host (check-host localhost - accept success or operational failure, never invalid-input)
"$APP" check-host localhost >/tmp/assignment3-test-out.log 2>&1
rc=$?
if [[ "$rc" -eq 0 || "$rc" -eq 1 ]]; then
    pass "check-host localhost returns 0 or 1 (exit $rc)"
else
    fail "check-host localhost should return 0 or 1, got $rc"
    cat /tmp/assignment3-test-out.log
fi

# 7. missing port (check-port with host but no port)
assert_exit "check-port with missing port returns exit code 2" 2 check-port localhost

# 8. non-numeric port
assert_exit "check-port with non-numeric port returns exit code 2" 2 check-port localhost abc

# 9. out-of-range port (low)
assert_exit "check-port with port 0 returns exit code 2" 2 check-port localhost 0

# 10. out-of-range port (high)
assert_exit "check-port with port 65536 returns exit code 2" 2 check-port localhost 65536

echo
echo "===================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "===================================="

[[ "$FAIL" -eq 0 ]]