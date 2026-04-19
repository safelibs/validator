#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
host-run.sh is retired for normal validator execution.
Use the Docker testcase runner: docker-entrypoint.sh <testcase-id> -- <command> [args...].
EOF
exit 64
