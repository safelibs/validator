#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-float-special-inf-nan-resolve
# @title: PyYAML safe_load resolves .inf, -.inf and .nan to Python float specials
# @description: Loads the three YAML 1.1 float specials (.inf, -.inf, .nan) and asserts safe_load returns the corresponding IEEE-754 Python floats: positive infinity, negative infinity, and a NaN that compares not-equal to itself.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, float
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import math
import yaml

doc = "p: .inf\nn: -.inf\nx: .nan\n"
data = yaml.safe_load(doc)
assert isinstance(data['p'], float) and math.isinf(data['p']) and data['p'] > 0, data['p']
assert isinstance(data['n'], float) and math.isinf(data['n']) and data['n'] < 0, data['n']
assert isinstance(data['x'], float) and math.isnan(data['x']), data['x']
# Canonical NaN identity check.
assert data['x'] != data['x'], 'NaN must compare unequal to itself'
PY
