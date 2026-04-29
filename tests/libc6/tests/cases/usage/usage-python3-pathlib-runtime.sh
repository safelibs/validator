#!/usr/bin/env bash
# @testcase: usage-python3-pathlib-runtime
# @title: Python pathlib runtime
# @description: Uses Python pathlib helpers to write and inspect a file path and verifies the result.
# @timeout: 180
# @tags: usage, python, text
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pathlib-runtime"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir" >"$tmpdir/out" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
path = root / "alpha.txt"
path.write_text("alpha payload\n")
print(path.name)
print(path.read_text().strip())
PY
validator_assert_contains "$tmpdir/out" 'alpha.txt'
validator_assert_contains "$tmpdir/out" 'alpha payload'
