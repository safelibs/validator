#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-safe-load-float-scientific-notation
# @title: PyYAML safe_load resolves '1.5e3' to the Python float 1500.0
# @description: Parses the document 'val: 1.5e3' via yaml.safe_load and asserts the resulting value is exactly the Python float 1500.0 of type float — pinning the libyaml implicit-resolver float-with-exponent path.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, float, scientific, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load('val: 1.5e3\n')
v = data['val']
assert isinstance(v, float), (v, type(v))
assert v == 1500.0, v
PY
