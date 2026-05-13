#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-load-anchor-alias-shared-list-roundtrip
# @title: PyYAML safe_load resolves &anchor / *alias references to a shared list object
# @description: Loads a YAML mapping where two keys reference the same anchored sequence and asserts the resulting Python values are not only equal but the exact same object (identity preserved), confirming the SafeConstructor's alias resolution semantics.
# @timeout: 60
# @tags: usage, python3-yaml, anchor, alias
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
defaults: &d
  - one
  - two
  - three
first: *d
second: *d
"""
data = yaml.safe_load(doc)
assert data['defaults'] == ['one', 'two', 'three'], data['defaults']
assert data['first'] is data['defaults'], 'expected alias to share object'
assert data['second'] is data['defaults'], 'expected alias to share object'
PY
