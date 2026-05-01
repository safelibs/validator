#!/usr/bin/env bash
# @testcase: usage-python3-yaml-pairs-construction-batch17
# @title: PyYAML !!pairs constructs a list of two-tuples preserving duplicates
# @description: Loads a YAML sequence tagged with !!pairs containing duplicate keys via yaml.safe_load and verifies the result is a list of two-element tuples that preserves both duplicate keys and the original ordering.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-pairs-construction-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

# !!pairs allows duplicate keys, unlike a plain mapping.
doc = (
    "kv: !!pairs\n"
    "  - one: 1\n"
    "  - two: 2\n"
    "  - one: 3\n"
)

data = yaml.safe_load(doc)
pairs = data["kv"]

# PyYAML constructs !!pairs as a list of two-element tuples.
assert isinstance(pairs, list), pairs
assert len(pairs) == 3, pairs
for entry in pairs:
    assert isinstance(entry, tuple), entry
    assert len(entry) == 2, entry

assert pairs == [("one", 1), ("two", 2), ("one", 3)], pairs

# Duplicate keys both survive (a regular mapping would have dropped one).
keys = [k for (k, _) in pairs]
assert keys.count("one") == 2, keys

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(repr(pairs))

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "one"
validator_assert_contains "$tmpdir/out" "two"
echo "OK"
