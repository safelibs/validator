#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-bytes-binary-tag-default-batch12
# @title: PyYAML dump bytes via default Dumper emits !!binary
# @description: Dumps a bytes payload through the default yaml.Dumper and verifies the emitted scalar uses the !!binary tag with base64-encoded content that round-trips via full_load.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-bytes-binary-tag-default-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import base64
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

payload = bytes([0, 1, 2, 3, 250, 251, 252, 253, 254, 255])
text = yaml.dump({"data": payload}, default_flow_style=False)

assert "!!binary" in text, text

# The emitted base64 (whitespace-stripped) must match.
expected = base64.b64encode(payload).decode("ascii")
joined = "".join(text.split())
assert expected in joined, (expected, joined)

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

# Round-trip with full_load (default unsafe loader still safely handles !!binary).
loaded = yaml.full_load(text)
assert isinstance(loaded["data"], bytes), type(loaded["data"])
assert loaded["data"] == payload, loaded["data"]

print("LEN", len(loaded["data"]))
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "!!binary"
echo "OK"
