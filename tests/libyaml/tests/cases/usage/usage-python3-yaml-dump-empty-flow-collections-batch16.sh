#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-empty-flow-collections-batch16
# @title: PyYAML yaml.dump preserves empty list and empty dict in flow style
# @description: Dumps a mapping containing an empty list and an empty dict with default_flow_style=False and verifies the empty collections are emitted in flow form ('[]' and '{}') and round-trip back to identical Python objects.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-empty-flow-collections-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

data = {"empty_list": [], "empty_dict": {}, "non_empty": [1, 2]}
text = yaml.dump(data, default_flow_style=False, sort_keys=False)

# PyYAML emits empty collections in flow form even when block style is the
# default, because they have no children to render in block form.
assert "empty_list: []" in text, text
assert "empty_dict: {}" in text, text

# The non-empty list still renders in block style under default_flow_style=False.
assert "non_empty:\n- 1\n- 2\n" in text, text

# Round-trip preserves both empty containers and their types.
loaded = yaml.safe_load(text)
assert loaded == data, loaded
assert loaded["empty_list"] == [] and isinstance(loaded["empty_list"], list)
assert loaded["empty_dict"] == {} and isinstance(loaded["empty_dict"], dict)

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "empty_list: []"
validator_assert_contains "$tmpdir/out.yaml" "empty_dict: {}"
echo "OK"
