#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-block-vs-flow-output
# @title: PyYAML CSafeDumper block vs flow output verification
# @description: Emits the same mapping with default_flow_style False and True via CSafeDumper and verifies block style omits braces while flow style uses braces.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/block.yaml" "$tmpdir/flow.yaml" <<'PY'
import sys
import yaml

block_path, flow_path = sys.argv[1], sys.argv[2]
value = {"name": "alpha", "items": [1, 2, 3]}

block = yaml.dump(value, Dumper=yaml.CSafeDumper, default_flow_style=False, sort_keys=False)
flow = yaml.dump(value, Dumper=yaml.CSafeDumper, default_flow_style=True, sort_keys=False)

# Block-style output should not start with a flow brace and should put items on
# their own lines.
assert not block.lstrip().startswith("{"), block
assert "name: alpha\n" in block, block
assert "- 1\n" in block, block

# Flow-style output should be a single flow mapping starting with `{`.
assert flow.lstrip().startswith("{"), flow
assert "[1, 2, 3]" in flow, flow

# Both must round-trip to the original value via CSafeLoader.
assert yaml.load(block, Loader=yaml.CSafeLoader) == value
assert yaml.load(flow, Loader=yaml.CSafeLoader) == value

with open(block_path, "w", encoding="utf-8") as fh:
    fh.write(block)
with open(flow_path, "w", encoding="utf-8") as fh:
    fh.write(flow)

print("STYLE_OK")
PY

# Block style: no braces in body lines.
! grep -q '^{' "$tmpdir/block.yaml"
validator_assert_contains "$tmpdir/block.yaml" 'name: alpha'
validator_assert_contains "$tmpdir/block.yaml" '- 1'

# Flow style: a single line with braces and bracketed sequence.
grep -q '^{' "$tmpdir/flow.yaml"
validator_assert_contains "$tmpdir/flow.yaml" '[1, 2, 3]'
echo "OK"
