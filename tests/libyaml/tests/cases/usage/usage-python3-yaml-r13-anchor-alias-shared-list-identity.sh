#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-anchor-alias-shared-list-identity
# @title: PyYAML safe_load anchored list and alias point at the same object
# @description: Loads a mapping where one key carries an anchored list and a second key references that anchor with a star alias, and asserts both values are not just equal but the identical Python object via the is operator.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, anchor-alias
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "a: &items\n  - 1\n  - 2\n  - 3\nb: *items\n"
data = yaml.safe_load(doc)
assert data['a'] == [1, 2, 3], data['a']
assert data['b'] is data['a'], 'alias must yield the same object as the anchor'
PY
