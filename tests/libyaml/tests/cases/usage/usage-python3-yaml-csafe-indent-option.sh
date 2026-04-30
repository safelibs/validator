#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-indent-option
# @title: PyYAML CSafeDumper indent option controls block indentation
# @description: Dumps a nested mapping with CSafeDumper using indent=6 and verifies six-space indentation is applied and the result round-trips.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/indent.yaml" <<'PY'
import sys
import yaml

dst = sys.argv[1]
value = {"outer": {"inner": {"leaf": 1}}}
text = yaml.dump(
    value,
    Dumper=yaml.CSafeDumper,
    indent=6,
    default_flow_style=False,
    sort_keys=False,
)

# We expect indentation steps of 6 spaces.
assert "      inner:" in text, text  # 6 spaces before inner
assert "            leaf: 1" in text, text  # 12 spaces before leaf

# Round-trip
assert yaml.load(text, Loader=yaml.CSafeLoader) == value

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("INDENT_OK")
PY

grep -q '^      inner:' "$tmpdir/indent.yaml"
grep -q '^            leaf: 1' "$tmpdir/indent.yaml"
echo "OK"
