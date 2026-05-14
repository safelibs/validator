#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-safe-load-omap-preserves-order
# @title: PyYAML safe_load on !!omap returns ordered (key, value) pairs in document order
# @description: Loads a YAML document with an explicit !!omap tag through yaml.safe_load and asserts the resulting list-of-pairs preserves the source ordering 'c','a','b'.
# @timeout: 60
# @tags: usage, python3-yaml, omap, order, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
ordered: !!omap
  - c: 3
  - a: 1
  - b: 2
"""
data = yaml.safe_load(doc)
pairs = data['ordered']
keys = []
for p in pairs:
    if isinstance(p, dict):
        keys.append(list(p.keys())[0])
    else:
        keys.append(p[0])
assert keys == ['c', 'a', 'b'], keys
print('ok keys=', keys)
PY
