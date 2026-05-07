#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-safe-load-explicit-float-tag
# @title: PyYAML safe_load coerces an integer scalar to float when tagged !!float
# @description: Loads a mapping whose value carries an explicit !!float tag on the integer literal 7 and asserts safe_load returns a Python float of value 7.0, exercising the SafeConstructor explicit-tag path that overrides the implicit int resolver.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, explicit-tag
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "x: !!float 7\n"
data = yaml.safe_load(doc)
v = data['x']
assert isinstance(v, float) and not isinstance(v, bool), (v, type(v))
assert v == 7.0, v
# Without the explicit tag the same scalar resolves to int.
plain = yaml.safe_load("x: 7\n")
assert isinstance(plain['x'], int) and plain['x'] == 7, plain
PY
