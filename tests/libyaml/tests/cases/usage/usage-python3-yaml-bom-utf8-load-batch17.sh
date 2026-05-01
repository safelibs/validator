#!/usr/bin/env bash
# @testcase: usage-python3-yaml-bom-utf8-load-batch17
# @title: PyYAML safe_load consumes a UTF-8 BOM at the start of the stream
# @description: Builds a YAML byte string prefixed with the UTF-8 BOM (EF BB BF) and verifies that yaml.safe_load on the bytes object consumes the BOM and returns the expected mapping with the first key intact and not prefixed by a stray BOM character.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-bom-utf8-load-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Write a BOM-prefixed YAML document to a file so the bytes are unambiguous.
printf '\xef\xbb\xbfname: bom-test\nvalue: 7\n' > "$tmpdir/in.yaml"

# Verify the BOM bytes are actually present in the source file.
head -c 3 "$tmpdir/in.yaml" | od -An -tx1 | tr -d ' \n' > "$tmpdir/bom-bytes"
validator_assert_contains "$tmpdir/bom-bytes" "efbbbf"

python3 - <<'PYCASE' "$case_id" "$tmpdir/in.yaml" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
src = sys.argv[2]
out_path = sys.argv[3]

with open(src, "rb") as fh:
    raw = fh.read()
assert raw.startswith(b"\xef\xbb\xbf"), raw[:8]

# safe_load on bytes must consume the BOM transparently.
data = yaml.safe_load(raw)
assert data == {"name": "bom-test", "value": 7}, data
keys = list(data.keys())
# The BOM character must not leak into any key name.
assert keys[0] == "name", keys
assert "﻿" not in keys[0], repr(keys[0])

# Same input via the C loader (when available) behaves identically.
loader = getattr(yaml, "CSafeLoader", yaml.SafeLoader)
data2 = yaml.load(raw, Loader=loader)
assert data2 == data, (data, data2)

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(repr(data))

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "bom-test"
echo "OK"
