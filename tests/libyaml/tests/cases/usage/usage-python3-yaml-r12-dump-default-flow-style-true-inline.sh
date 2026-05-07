#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-dump-default-flow-style-true-inline
# @title: PyYAML safe_dump with default_flow_style=True emits inline flow form
# @description: Dumps a nested dict with default_flow_style=True and asserts the output uses inline {} and [] flow markers rather than block style, then reloads to confirm the round-trip preserves values.
# @timeout: 60
# @tags: usage, python3-yaml, dump, flow-style
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'a': 1, 'b': [10, 20], 'c': {'x': 'y'}}
out = yaml.safe_dump(src, default_flow_style=True)
assert '{' in out and '}' in out, out
assert '[' in out and ']' in out, out
# Block-style indent markers should not appear
assert '\n  ' not in out, out
back = yaml.safe_load(out)
assert back == src, (back, src)
PY
