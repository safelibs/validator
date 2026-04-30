#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-block-style-list-batch14
# @title: PyYAML dump forces block style on a list
# @description: Dumps a list two ways via yaml.dump — once with default_flow_style=False forcing block style, once with True forcing flow style — and verifies the block form uses leading hyphens on separate lines while the flow form uses bracketed inline syntax, with both round-tripping to the same Python list.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-block-style-list-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/block.yaml" "$tmpdir/flow.yaml"
import sys
import yaml

case_id = sys.argv[1]
block_path = sys.argv[2]
flow_path = sys.argv[3]

data = ["alpha", "beta", "gamma"]

block_text = yaml.dump(data, default_flow_style=False)
flow_text = yaml.dump(data, default_flow_style=True)

with open(block_path, "w", encoding="utf-8") as fh:
    fh.write(block_text)
with open(flow_path, "w", encoding="utf-8") as fh:
    fh.write(flow_text)

# Block form: each entry on its own line beginning with "- ".
block_lines = [line for line in block_text.splitlines() if line.strip()]
assert all(line.startswith("- ") for line in block_lines), block_text
assert len(block_lines) == 3, block_text
assert "[" not in block_text and "]" not in block_text, block_text

# Flow form: a single inline sequence using brackets and commas.
assert flow_text.startswith("["), flow_text
assert "]" in flow_text, flow_text
assert "," in flow_text, flow_text
# Flow form must not use the block "- " marker.
assert not any(line.startswith("- ") for line in flow_text.splitlines()), flow_text

# Both round-trip identically.
assert yaml.safe_load(block_text) == data
assert yaml.safe_load(flow_text) == data

print("OK")
PYCASE

# Block form has hyphen entries, flow form has square brackets.
grep -Eq '^- alpha$' "$tmpdir/block.yaml"
grep -Eq '\[' "$tmpdir/flow.yaml"
grep -Eq '\]' "$tmpdir/flow.yaml"
echo "OK"
