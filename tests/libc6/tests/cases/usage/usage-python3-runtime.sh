#!/usr/bin/env bash
# @testcase: usage-python3-runtime
# @title: Python runs libc-backed runtime
# @description: Starts Python, performs arithmetic, and prints a computed value.
# @timeout: 120
# @tags: usage, python
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-runtime"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' >"$tmpdir/out"
print("answer=%d" % (6 * 7))
PY
validator_assert_contains "$tmpdir/out" 'answer=42'
