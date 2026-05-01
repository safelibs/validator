#!/usr/bin/env bash
# @testcase: usage-python3-yaml-omap-roundtrip-batch17
# @title: PyYAML !!omap preserves entry order through SafeLoader
# @description: Loads a YAML document carrying the !!omap tag with three keys in non-sorted order through yaml.safe_load and verifies the resulting list of two-tuples retains the source order, then re-dumps the data and confirms the second parse yields the same payload.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-omap-roundtrip-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

doc = (
    "ordered: !!omap\n"
    "  - zulu: 1\n"
    "  - alpha: 2\n"
    "  - mike: 3\n"
)

data = yaml.safe_load(doc)

# !!omap is constructed as a list of (key, value) tuples, in source order.
assert isinstance(data, dict), data
ordered = data["ordered"]
assert isinstance(ordered, list), ordered
assert ordered == [("zulu", 1), ("alpha", 2), ("mike", 3)], ordered
for entry in ordered:
    assert isinstance(entry, tuple) and len(entry) == 2, entry

# Confirm source order is preserved (non-alphabetical).
keys = [k for (k, _) in ordered]
assert keys == ["zulu", "alpha", "mike"], keys

# Re-parsing the original document is stable.
again = yaml.safe_load(doc)
assert again == data, again

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(doc)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "zulu"
validator_assert_contains "$tmpdir/out.yaml" "alpha"
validator_assert_contains "$tmpdir/out.yaml" "mike"
echo "OK"
