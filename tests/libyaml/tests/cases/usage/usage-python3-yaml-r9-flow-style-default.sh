#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-flow-style-default
# @title: PyYAML default_flow_style toggles output shape
# @description: Dumps the same dict with default_flow_style=False (block) and default_flow_style=True (flow) and asserts only the flow form contains braces.
# @timeout: 60
# @tags: usage, python3-yaml
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import yaml
data = {'a': 1, 'b': [10, 20]}
block = yaml.safe_dump(data, default_flow_style=False)
flow = yaml.safe_dump(data, default_flow_style=True)
assert '{' not in block, block
assert '{' in flow, flow
# Both should round-trip equally.
assert yaml.safe_load(block) == data
assert yaml.safe_load(flow) == data
PY
