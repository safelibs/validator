#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-safe-load-anchor-alias-identity
# @title: PyYAML safe_load resolves YAML aliases into the same Python object as their anchor
# @description: Loads a YAML document where a mapping value is an alias to a previously anchored list via yaml.safe_load, then asserts the two loaded entries are the same Python list object (identity, not just equality).
# @timeout: 60
# @tags: usage, python3-yaml, anchor, alias, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
a: &items [1, 2, 3]
b: *items
"""
data = yaml.safe_load(doc)
assert data['a'] == [1, 2, 3], data['a']
assert data['b'] is data['a'], (id(data['a']), id(data['b']))
PY
