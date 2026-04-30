#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-line-break-crlf-batch16
# @title: PyYAML yaml.dump with line_break='\r\n' emits DOS line endings
# @description: Dumps a multi-key mapping with line_break set to '\r\n' and verifies every line break in the output uses CRLF and the bytes contain CR characters before each LF.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-line-break-crlf-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

data = {"a": 1, "b": 2, "c": 3}
text = yaml.dump(data, line_break="\r\n", default_flow_style=False, sort_keys=True)

assert "\r\n" in text, repr(text)
# Every newline in the output must be a CRLF, never a bare LF.
lf_total = text.count("\n")
crlf_total = text.count("\r\n")
assert lf_total == crlf_total, (lf_total, crlf_total, repr(text))
assert lf_total >= 3, repr(text)

with open(dst, "wb") as fh:
    fh.write(text.encode("utf-8"))

with open(dst, "rb") as fh:
    raw = fh.read()
assert b"\r\n" in raw, raw
assert raw.count(b"\r\n") == raw.count(b"\n"), raw

# Round-trip works: PyYAML accepts CRLF input.
loaded = yaml.safe_load(raw.decode("utf-8"))
assert loaded == data, loaded

print("CRLF", crlf_total)
print("OK")
PYCASE

# The on-disk file must contain at least one CR byte.
if ! grep -q $'\r' "$tmpdir/out.yaml"; then
  echo "expected CRLF line endings in output" >&2
  od -c "$tmpdir/out.yaml" | head -5 >&2
  exit 1
fi
echo "OK"
