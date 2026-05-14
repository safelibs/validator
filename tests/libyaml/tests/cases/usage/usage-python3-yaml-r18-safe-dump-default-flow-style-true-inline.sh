#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-safe-dump-default-flow-style-true-inline
# @title: PyYAML safe_dump default_flow_style=True emits a flow-style inline mapping
# @description: Dumps a small dict via yaml.safe_dump with default_flow_style=True, asserts the rendered output starts with a brace and contains the inline key:value pairs delimited by commas — pinning the flow-style emitter contract.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, flow-style, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = {'a': 1, 'b': 2}
out = yaml.safe_dump(data, default_flow_style=True).strip()
assert out.startswith('{') and out.endswith('}'), out
assert 'a: 1' in out and 'b: 2' in out, out
PY
