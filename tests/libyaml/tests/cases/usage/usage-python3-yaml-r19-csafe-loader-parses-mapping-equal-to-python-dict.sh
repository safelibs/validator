#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-csafe-loader-parses-mapping-equal-to-python-dict
# @title: PyYAML yaml.load with CSafeLoader returns the same dict as Python comparison literal
# @description: Loads a small inline mapping document via yaml.load(Loader=yaml.CSafeLoader) and asserts the result equals the Python literal {'a': 1, 'b': 2, 'c': 3} — confirming the libyaml C-backend SafeLoader produces canonical Python dicts.
# @timeout: 60
# @tags: usage, python3-yaml, csafe-loader, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.load('a: 1\nb: 2\nc: 3\n', Loader=yaml.CSafeLoader)
assert data == {'a': 1, 'b': 2, 'c': 3}, data
PY
