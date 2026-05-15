#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-safe-load-yes-as-bool-true
# @title: PyYAML safe_load resolves the bare scalar 'true' to Python bool True
# @description: Parses 'flag: true' via yaml.safe_load and asserts the value is the Python bool True (type bool, equal to True) — pinning libyaml's YAML 1.1 implicit bool resolver for the 'true' token.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, bool, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load('flag: true\n')
v = data['flag']
assert isinstance(v, bool), (v, type(v))
assert v is True, v
PY
