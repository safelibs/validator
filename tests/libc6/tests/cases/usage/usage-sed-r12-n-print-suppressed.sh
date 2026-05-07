#!/usr/bin/env bash
# @testcase: usage-sed-r12-n-print-suppressed
# @title: sed -n suppresses default output and only prints matching p commands
# @description: Runs sed -n with /needle/p over a multi-line input and verifies only matching lines are printed via the explicit p command (default output is suppressed).
# @timeout: 60
# @tags: usage, sed
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
keep needle one
drop this
keep needle two
also drop
EOF

LC_ALL=C sed -n '/needle/p' "$tmpdir/in.txt" >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
keep needle one
keep needle two
EOF

cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"
