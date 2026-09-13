#!/usr/bin/env bash
#
# build.sh
# Assignment 3 - CI/CD with GitHub Actions
#
# Builds the Docker image and runs smoke tests against it: help,
# system-info, and an invalid-command test. This is what the CI
# pipeline's "docker" job runs.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

IMAGE="devops-tool-ci"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

echo "===================================="
echo " Docker Build & Smoke Tests"
echo "===================================="

echo "Building image..."
if docker build -t "$IMAGE" . >/tmp/assignment3-build.log 2>&1; then
    pass "Docker image builds successfully"
else
    fail "Docker image failed to build"
    cat /tmp/assignment3-build.log
    exit 1
fi

if docker run --rm "$IMAGE" help >/tmp/assignment3-smoke.log 2>&1; then
    pass "Smoke test: help command works"
else
    fail "Smoke test: help command failed"
    cat /tmp/assignment3-smoke.log
fi

if docker run --rm "$IMAGE" system-info >/tmp/assignment3-smoke.log 2>&1; then
    pass "Smoke test: system-info command works"
else
    fail "Smoke test: system-info command failed"
    cat /tmp/assignment3-smoke.log
fi

docker run --rm "$IMAGE" invalid-command >/tmp/assignment3-smoke.log 2>&1
rc=$?
if [[ "$rc" -ne 0 ]]; then
    pass "Smoke test: invalid command correctly returns non-zero (exit $rc)"
else
    fail "Smoke test: invalid command should return non-zero, got $rc"
fi

docker image rm "$IMAGE" >/dev/null 2>&1 || true

echo
echo "===================================="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "===================================="

[[ "$FAIL" -eq 0 ]]