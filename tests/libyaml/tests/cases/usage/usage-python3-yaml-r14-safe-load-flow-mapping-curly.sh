#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-safe-load-flow-mapping-curly
# @title: PyYAML safe_load parses inline flow mapping "{a: 1, b: 2}" into a Python dict
# @description: Loads a top-level value declared as an inline flow mapping using curly braces and asserts safe_load yields the equivalent Python dict with two int values, exercising the SafeLoader flow-mapping path which is structurally distinct from block-mapping parsing.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, flow-mapping
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "values: {a: 1, b: 2}\n"
data = yaml.safe_load(doc)
inner = data['values']
assert isinstance(inner, dict), type(inner)
assert inner == {'a': 1, 'b': 2}, inner
# Both values are real ints, not strings.
for k, v in inner.items():
    assert isinstance(v, int) and not isinstance(v, bool), (k, v, type(v))
PY
