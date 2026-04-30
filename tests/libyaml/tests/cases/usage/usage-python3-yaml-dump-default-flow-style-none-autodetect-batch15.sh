#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-default-flow-style-none-autodetect-batch15
# @title: PyYAML dump default_flow_style=None auto-detects nested vs leaf
# @description: Calls yaml.dump with default_flow_style=None on a structure that mixes a leaf list of scalars with a nested mapping containing further structure. Verifies the auto-detect heuristic emits the leaf list inline ([..]) while the outer mapping uses block style (one key per line), in contrast to default_flow_style=False (all block) and =True (all flow).
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-default-flow-style-none-autodetect-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

data = {
    "leaf_list": [1, 2, 3],
    "nested_map": {"inner": {"a": 1, "b": 2}},
}

text_none = yaml.dump(data, default_flow_style=None, sort_keys=True)
text_block = yaml.dump(data, default_flow_style=False, sort_keys=True)
text_flow = yaml.dump(data, default_flow_style=True, sort_keys=True)

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write("--- none ---\n" + text_none)
    fh.write("--- block ---\n" + text_block)
    fh.write("--- flow ---\n" + text_flow)

# default_flow_style=None: leaf list of scalars goes flow ([1, 2, 3]),
# while the outer mapping (which contains nested non-scalar children) stays block.
assert "[1, 2, 3]" in text_none, text_none
# Outer map is block: key on its own line followed by colon and newline.
assert "leaf_list:" in text_none, text_none
assert "nested_map:" in text_none, text_none
# Block mode never emits the inline [ ] list form.
assert "[1, 2, 3]" not in text_block, text_block
assert "- 1" in text_block, text_block
# Full flow mode wraps everything: outer mapping uses braces.
assert text_flow.lstrip().startswith("{"), text_flow

# All three round-trip back to the same Python structure.
for label, text in [("none", text_none), ("block", text_block), ("flow", text_flow)]:
    loaded = yaml.safe_load(text)
    assert loaded == data, (label, loaded)

print("FLOW_NONE_OK")
PYCASE

validator_assert_contains "$tmpdir/out" "[1, 2, 3]"
validator_assert_contains "$tmpdir/out" "leaf_list:"
echo "OK"
