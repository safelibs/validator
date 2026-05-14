#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-safe-load-set-tag-yields-python-set
# @title: PyYAML safe_load on !!set tag returns a Python set with the declared members
# @description: Loads a YAML mapping with an explicit !!set tag whose members are alpha, beta, gamma via yaml.safe_load and asserts the resulting value is a Python set equal to {'alpha', 'beta', 'gamma'}.
# @timeout: 60
# @tags: usage, python3-yaml, set-tag, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
members: !!set
  ? alpha
  ? beta
  ? gamma
"""
data = yaml.safe_load(doc)
members = data['members']
assert isinstance(members, set), type(members)
assert members == {'alpha', 'beta', 'gamma'}, members
PY
