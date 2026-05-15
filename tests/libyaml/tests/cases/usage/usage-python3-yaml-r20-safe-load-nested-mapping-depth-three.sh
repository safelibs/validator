#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-safe-load-nested-mapping-depth-three
# @title: PyYAML safe_load parses a three-deep block mapping into nested dicts
# @description: Parses 'a:\n  b:\n    c: v\n' via yaml.safe_load and asserts the resulting structure is {'a': {'b': {'c': 'v'}}} with three nested Python dicts, pinning the libyaml block-mapping indentation parser.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, nested-mapping, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = 'a:\n  b:\n    c: v\n'
data = yaml.safe_load(doc)
assert isinstance(data, dict), type(data)
assert isinstance(data['a'], dict), type(data['a'])
assert isinstance(data['a']['b'], dict), type(data['a']['b'])
assert data == {'a': {'b': {'c': 'v'}}}, data
PY
