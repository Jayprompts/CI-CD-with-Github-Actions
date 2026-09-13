#!/usr/bin/env bash
#
# app.sh
# Assignment 3 - CI/CD with GitHub Actions
#
# Usage:
#   app.sh system-info
#   app.sh check-host <host>
#   app.sh check-port <host> <port>
#   app.sh help
#
# Exit codes:
#   0 - success
#   1 - operational/runtime failure (host unreachable, port closed)
#   2 - invalid command or invalid/missing input

set -u

print_help() {
    cat <<EOF
devops-tool - Assignment 3 CLI

Usage:
  app.sh system-info               Display system information
  app.sh check-host <host>         Resolve and check a host
  app.sh check-port <host> <port>  Validate a port and check TCP connectivity
  app.sh help                      Display this help message

Exit codes:
  0  success
  1  operational/runtime failure
  2  invalid command or invalid/missing input
EOF
}

cmd_system_info() {
    echo "===================================="
    echo " System Information"
    echo "===================================="
    echo "Hostname        : $(hostname)"
    echo "Current User    : $(whoami)"
    echo "Date/Time       : $(date '+%Y-%m-%d %H:%M:%S')"

    if [ -f /etc/os-release ]; then
        OS_NAME=$(. /etc/os-release && echo "$PRETTY_NAME")
    else
        OS_NAME=$(uname -s)
    fi
    echo "Operating System: ${OS_NAME}"
    echo "Kernel Version  : $(uname -r)"

    return 0
}

cmd_check_host() {
    local host="${1:-}"

    if [[ -z "$host" ]]; then
        echo "Error: check-host requires a host argument." >&2
        echo "Usage: app.sh check-host <host>" >&2
        return 2
    fi

    if ! [[ "$host" =~ ^[A-Za-z0-9.:_-]+$ ]]; then
        echo "Error: '$host' is not a valid hostname or IP address." >&2
        return 2
    fi

    echo "===================================="
    echo " Host Check: $host"
    echo "===================================="

    local status=0
    local resolved=""

    if command -v getent >/dev/null 2>&1; then
        resolved=$(getent hosts "$host" 2>/dev/null | awk '{print $1}' | head -n1)
    fi

    if [[ -n "$resolved" ]]; then
        echo "Resolved Address: $resolved"
    else
        echo "Resolved Address: could not resolve '$host'"
        status=1
    fi

    if command -v ping >/dev/null 2>&1 && ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
        echo "Connectivity    : REACHABLE"
    else
        echo "Connectivity    : UNREACHABLE"
        status=1
    fi

    return "$status"
}

cmd_check_port() {
    local host="${1:-}"
    local port="${2:-}"

    if [[ -z "$host" ]]; then
        echo "Error: check-port requires a host argument." >&2
        echo "Usage: app.sh check-port <host> <port>" >&2
        return 2
    fi

    if ! [[ "$host" =~ ^[A-Za-z0-9.:_-]+$ ]]; then
        echo "Error: '$host' is not a valid hostname or IP address." >&2
        return 2
    fi

    if [[ -z "$port" ]]; then
        echo "Error: check-port requires a port argument." >&2
        echo "Usage: app.sh check-port <host> <port>" >&2
        return 2
    fi

    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "Error: port must be a whole number." >&2
        return 2
    fi

    if (( port < 1 || port > 65535 )); then
        echo "Error: port must be between 1 and 65535." >&2
        return 2
    fi

    echo "===================================="
    echo " Port Check: $host:$port"
    echo "===================================="

    if timeout 3 bash -c "echo > /dev/tcp/${host}/${port}" 2>/dev/null; then
        echo "Port $port: OPEN"
        return 0
    else
        echo "Port $port: CLOSED or unreachable"
        return 1
    fi
}

# --- Main dispatch ---
COMMAND="${1:-}"

if [[ -z "$COMMAND" ]]; then
    echo "Error: a command is required." >&2
    print_help >&2
    exit 2
fi

case "$COMMAND" in
    system-info)
        cmd_system_info
        exit $?
        ;;
    check-host)
        shift
        cmd_check_host "${1:-}"
        exit $?
        ;;
    check-port)
        shift
        cmd_check_port "${1:-}" "${2:-}"
        exit $?
        ;;
    help|-h|--help)
        print_help
        exit 0
        ;;
    *)
        echo "Error: unknown command '$COMMAND'." >&2
        print_help >&2
        exit 2
        ;;
esac