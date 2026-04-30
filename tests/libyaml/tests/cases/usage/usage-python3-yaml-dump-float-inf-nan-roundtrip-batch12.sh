#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-float-inf-nan-roundtrip-batch12
# @title: PyYAML dump float inf and nan round-trip
# @description: Dumps floating-point infinity and NaN with yaml.dump and verifies the .inf and .nan literal scalars are emitted and round-trip correctly.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-float-inf-nan-roundtrip-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import math
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

data = {
    "pos": float("inf"),
    "neg": float("-inf"),
    "nan": float("nan"),
}
text = yaml.dump(data, default_flow_style=False, sort_keys=True)

assert ".inf" in text, text
assert "-.inf" in text, text
assert ".nan" in text, text

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

loaded = yaml.safe_load(text)
assert math.isinf(loaded["pos"]) and loaded["pos"] > 0, loaded
assert math.isinf(loaded["neg"]) and loaded["neg"] < 0, loaded
assert math.isnan(loaded["nan"]), loaded

print("POS", loaded["pos"])
print("NEG", loaded["neg"])
print("NAN_IS_NAN", math.isnan(loaded["nan"]))
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" ".inf"
validator_assert_contains "$tmpdir/out.yaml" "-.inf"
validator_assert_contains "$tmpdir/out.yaml" ".nan"
echo "OK"
