#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-safe-load-utf8-non-ascii-scalar-preserved
# @title: PyYAML safe_load preserves a UTF-8 non-ASCII scalar as a Python str
# @description: Feeds 'name: café\n' (UTF-8 encoded) into yaml.safe_load and asserts the value is the Python str 'café', confirming libyaml's UTF-8 scalar decode produces the exact unicode characters.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, utf8, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = 'name: café\n'
data = yaml.safe_load(doc)
v = data['name']
assert isinstance(v, str), (v, type(v))
assert v == 'café', repr(v)
PY
