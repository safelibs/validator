#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-safe-load-empty-flow-sequence-empty-list
# @title: PyYAML safe_load on an empty flow sequence [] yields an empty Python list
# @description: Parses the YAML scalar 'k: []' via yaml.safe_load and asserts the resulting value is a Python list of length zero — pinning the libyaml empty-flow-sequence construction path.
# @timeout: 60
# @tags: usage, python3-yaml, empty-flow, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load('k: []\n')
assert data == {'k': []}, data
assert isinstance(data['k'], list), type(data['k'])
assert len(data['k']) == 0, data['k']
PY
