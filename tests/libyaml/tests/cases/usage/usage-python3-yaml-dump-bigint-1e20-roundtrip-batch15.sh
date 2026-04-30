#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-bigint-1e20-roundtrip-batch15
# @title: PyYAML dump roundtrip of arbitrary-precision integer 10**20
# @description: Dumps a Python arbitrary-precision integer (10**20, well beyond int64) with yaml.dump, asserts the emitted scalar is the exact decimal digit string, and verifies yaml.safe_load reads it back as a Python int with the same numeric value.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-bigint-1e20-roundtrip-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

bigint = 10 ** 20  # 100000000000000000000, exceeds 2**63 (~9.22e18).
assert bigint > 2 ** 63, bigint

text = yaml.dump({"big": bigint}, default_flow_style=False, sort_keys=True)
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

# Emitted as the literal decimal digit string, untagged.
assert "big: 100000000000000000000" in text, text
assert "!!" not in text, text

loaded = yaml.safe_load(text)
assert isinstance(loaded["big"], int), type(loaded["big"])
assert loaded["big"] == bigint, (loaded["big"], bigint)

print("BIGINT_OK", loaded["big"])
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "big: 100000000000000000000"
if grep -Fq '!!' "$tmpdir/out.yaml"; then
  echo "unexpected explicit tag in output" >&2
  exit 1
fi
echo "OK"
