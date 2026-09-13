#!/usr/bin/env bash
#
# lint.sh
# Assignment 3 - CI/CD with GitHub Actions
#
# Checks that required project files exist and that every Bash script
# has valid syntax. If ShellCheck is installed, runs it as an additional
# (non-fatal) check.

set -u

FAIL=0

REQUIRED_FILES=(
    "README.md"
    "app/app.sh"
    "scripts/lint.sh"
    "scripts/build.sh"
    "tests/test.sh"
    "Dockerfile"
    "compose.yaml"
    ".dockerignore"
    ".github/workflows/ci.yml"
)

echo "===================================="
echo " Lint: required files"
echo "===================================="
for f in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$f" ]]; then
        echo "OK   : $f"
    else
        echo "FAIL : missing required file: $f"
        FAIL=1
    fi
done

echo
echo "===================================="
echo " Lint: Bash syntax"
echo "===================================="
SCRIPT_FILES=$(find app scripts tests -type f -name "*.sh" 2>/dev/null)

if [[ -z "$SCRIPT_FILES" ]]; then
    echo "FAIL : no shell scripts found under app/, scripts/, tests/"
    FAIL=1
else
    while IFS= read -r f; do
        if bash -n "$f" 2>/tmp/lint-syntax-error.log; then
            echo "OK   : $f"
        else
            echo "FAIL : syntax error in $f"
            cat /tmp/lint-syntax-error.log
            FAIL=1
        fi
    done <<< "$SCRIPT_FILES"
fi

echo
echo "===================================="
echo " Lint: ShellCheck (optional, non-fatal)"
echo "===================================="
if command -v shellcheck >/dev/null 2>&1; then
    while IFS= read -r f; do
        echo "--- $f ---"
        shellcheck "$f" || true
    done <<< "$SCRIPT_FILES"
else
    echo "shellcheck not installed - skipping (optional check)"
fi

echo
if [[ "$FAIL" -eq 0 ]]; then
    echo "Lint passed."
else
    echo "Lint failed."
fi

exit "$FAIL"