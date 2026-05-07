#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-safe-load-flow-sequence-square
# @title: PyYAML safe_load parses inline flow sequence "[1, 2, 3]" into a Python list
# @description: Loads a top-level mapping whose value is an inline flow sequence using square brackets and asserts safe_load yields a Python list of three int elements with the declared order, exercising the SafeLoader flow-sequence path that is structurally distinct from block-sequence parsing.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, flow-sequence
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "items: [1, 2, 3]\n"
data = yaml.safe_load(doc)
assert isinstance(data, dict), type(data)
items = data['items']
assert isinstance(items, list), type(items)
assert items == [1, 2, 3], items
# Each entry must have been resolved as int, not as string.
for v in items:
    assert isinstance(v, int) and not isinstance(v, bool), (v, type(v))
PY
