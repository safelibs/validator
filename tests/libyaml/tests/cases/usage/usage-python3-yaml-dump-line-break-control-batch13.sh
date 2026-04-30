#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-line-break-control-batch13
# @title: PyYAML dump with explicit line_break='\n'
# @description: Dumps a mapping with yaml.dump and line_break='\n' and verifies output uses LF line endings exclusively (no CR bytes present).
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-line-break-control-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

data = {"a": 1, "b": 2, "c": 3}
text = yaml.dump(data, line_break="\n", default_flow_style=False, sort_keys=True)

assert "\r" not in text, repr(text)
assert text.endswith("\n"), repr(text)
assert text.count("\n") >= 3, repr(text)

with open(dst, "wb") as fh:
    fh.write(text.encode("utf-8"))

with open(dst, "rb") as fh:
    raw = fh.read()
assert b"\r" not in raw, raw

print("LINES", text.count("\n"))
print("OK")
PYCASE

if grep -q $'\r' "$tmpdir/out.yaml"; then
  echo "unexpected CR in output" >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out.yaml" "a:"
echo "OK"
