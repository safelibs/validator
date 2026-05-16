#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-load-shared-anchor-list-identity-deep
# @title: PyYAML safe_load preserves object identity for a list anchored once and aliased inside a list-of-list
# @description: Loads a document with a list anchor &xs reused as an item inside another list and asserts both occurrences refer to the same Python list object via 'is' — pinning libyaml's anchor/alias graph reconstruction through python3-yaml's safe loader.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, anchor, alias, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
- &xs [1, 2, 3]
- [a, *xs]
"""
data = yaml.safe_load(doc)
assert isinstance(data, list) and len(data) == 2, data
first = data[0]
inner = data[1][1]
assert first is inner, (id(first), id(inner))
assert first == [1, 2, 3], first
PY
