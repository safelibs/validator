#!/usr/bin/env bash
# @testcase: usage-python3-yaml-binary-tag-roundtrip
# @title: PyYAML binary tag base64 round-trip via CSafe backend
# @description: Round-trips raw bytes through CSafeDumper and CSafeLoader using the !!binary tag and confirms base64 encoding and exact byte recovery.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/bin.yaml" <<'PY'
import base64
import sys
import yaml

dst = sys.argv[1]
payload = bytes(range(256))  # all byte values
text = yaml.dump({"data": payload}, Dumper=yaml.CSafeDumper)

assert "!!binary" in text, text
# Decode and confirm we round-trip.
loaded = yaml.load(text, Loader=yaml.CSafeLoader)
assert isinstance(loaded["data"], bytes), type(loaded["data"])
assert loaded["data"] == payload, "binary round-trip mismatch"
assert len(loaded["data"]) == 256

# Also verify the embedded base64 actually decodes to the same payload.
expected_b64 = base64.b64encode(payload).decode("ascii")
joined = "".join(text.split())  # strip whitespace
assert expected_b64 in joined, "base64 payload missing from emitted text"

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("BINARY_OK", len(loaded["data"]))
PY

validator_assert_contains "$tmpdir/bin.yaml" '!!binary'
echo "OK"
