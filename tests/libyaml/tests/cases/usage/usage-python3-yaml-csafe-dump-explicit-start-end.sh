#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-dump-explicit-start-end
# @title: PyYAML CSafeDumper explicit start and end markers
# @description: Dumps a mapping with explicit_start and explicit_end markers using CSafeDumper and verifies both directives appear and round-trip cleanly.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.yaml" <<'PY'
import sys
import yaml

dst = sys.argv[1]
value = {"key": "alpha", "count": 7}
text = yaml.dump(
    value,
    Dumper=yaml.CSafeDumper,
    explicit_start=True,
    explicit_end=True,
    default_flow_style=False,
    sort_keys=False,
)

assert text.startswith("---\n"), f"missing explicit start: {text!r}"
assert text.rstrip("\n").endswith("..."), f"missing explicit end: {text!r}"

# Ensure both markers are present exactly once.
assert text.count("---") == 1
assert text.count("...") == 1

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

# Round-trip via CSafeLoader.
back = yaml.load(text, Loader=yaml.CSafeLoader)
assert back == value, f"round-trip mismatch: {back!r}"
print("MARKERS_OK")
PY

grep -q '^---$' "$tmpdir/out.yaml"
grep -q '^\.\.\.$' "$tmpdir/out.yaml"
validator_assert_contains "$tmpdir/out.yaml" 'key: alpha'
validator_assert_contains "$tmpdir/out.yaml" 'count: 7'
echo "OK"
