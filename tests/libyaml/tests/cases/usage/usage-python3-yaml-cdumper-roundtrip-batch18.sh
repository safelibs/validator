#!/usr/bin/env bash
# @testcase: usage-python3-yaml-cdumper-roundtrip-batch18
# @title: PyYAML yaml.CDumper (libyaml-backed full dumper) round-trips a mixed structure
# @description: Uses yaml.CDumper, the libyaml-backed C variant of the full dumper, to serialize a mixed Python structure (dict with int, float, list, and bool values), then parses the output back with yaml.CSafeLoader and verifies value-level equality and type preservation across the round-trip.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-cdumper-roundtrip-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

assert hasattr(yaml, "CDumper"), "yaml.CDumper missing -- python3-yaml not linked against libyaml"
assert hasattr(yaml, "CSafeLoader"), "yaml.CSafeLoader missing -- python3-yaml not linked against libyaml"

data = {
    "name": "beta",
    "count": 17,
    "ratio": 0.25,
    "enabled": True,
    "tags": ["alpha", "beta", "gamma"],
}

text = yaml.dump(data, Dumper=yaml.CDumper, default_flow_style=False, sort_keys=True)

# CDumper must produce a parseable block-style document.
assert "name: beta" in text, text
assert "count: 17" in text, text
assert "enabled: true" in text, text
assert "- alpha" in text, text

loaded = yaml.load(text, Loader=yaml.CSafeLoader)
assert loaded == data, loaded
assert isinstance(loaded["count"], int), type(loaded["count"])
assert isinstance(loaded["ratio"], float), type(loaded["ratio"])
assert isinstance(loaded["enabled"], bool), type(loaded["enabled"])
assert isinstance(loaded["tags"], list), type(loaded["tags"])

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "name: beta"
validator_assert_contains "$tmpdir/out.yaml" "count: 17"
validator_assert_contains "$tmpdir/out.yaml" "enabled: true"
echo "OK"
