#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-load-flow-vs-block-equivalent-result
# @title: PyYAML safe_load yields equal mappings for the same data in flow vs block style
# @description: Loads the same data as a block mapping ('a: 1\\nb: 2') and as a flow mapping ('{a: 1, b: 2}') via yaml.safe_load and asserts the two resulting dicts compare equal — pinning libyaml's parser equivalence of flow and block style through python3-yaml.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, flow, block, equivalence, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

block = "a: 1\nb: 2\n"
flow = "{a: 1, b: 2}\n"
b = yaml.safe_load(block)
f = yaml.safe_load(flow)
assert b == f == {'a': 1, 'b': 2}, (b, f)
PY
