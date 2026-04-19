#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
tests/run.sh no longer selects or runs the library test suite.
Run a selected testcase through docker-entrypoint.sh <testcase-id> -- <command> [args...].
EOF
exit 64
