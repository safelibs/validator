#!/usr/bin/env bash
# @testcase: usage-python3-file-io
# @title: Python file I/O runtime
# @description: Runs Python file creation and reading through the platform runtime.
# @timeout: 180
# @tags: usage, python, filesystem
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-file-io"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/out"
from pathlib import Path
import sys
path = Path(sys.argv[1])
path.write_text("python io payload\n")
print(path.read_text().strip())
PY
validator_assert_contains "$tmpdir/out" 'python io payload'
