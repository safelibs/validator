#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-nested-list-of-dicts-batch12
# @title: PyYAML dump nested list of dicts
# @description: Dumps a list of dicts with yaml.dump and verifies block-style indentation, dash markers, and full round-trip equality.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-nested-list-of-dicts-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

data = [
    {"name": "alice", "age": 30},
    {"name": "bob", "age": 25},
    {"name": "carol", "age": 40},
]
text = yaml.dump(data, default_flow_style=False, sort_keys=True)

# Each list element is introduced by "- ".
dash_lines = [ln for ln in text.splitlines() if ln.startswith("- ")]
assert len(dash_lines) == 3, text
# Continuation keys within a dict are indented by 2 spaces under the dash.
indented = [ln for ln in text.splitlines() if ln.startswith("  ") and ":" in ln]
assert len(indented) >= 3, text

assert yaml.safe_load(text) == data, text

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("DASHES", len(dash_lines))
print("INDENTED", len(indented))
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "- age:"
validator_assert_contains "$tmpdir/out.yaml" "name: alice"
validator_assert_contains "$tmpdir/out.yaml" "name: bob"
echo "OK"
