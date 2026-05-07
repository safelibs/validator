#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-safe-load-explicit-set-tag
# @title: PyYAML safe_load constructs Python set from !!set tag
# @description: Loads a mapping value tagged with !!set whose keys are null-valued and asserts safe_load returns a Python set containing exactly those keys, exercising the SafeConstructor !!set handler.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, set
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
colors: !!set
  ? red
  ? green
  ? blue
"""
data = yaml.safe_load(doc)
assert isinstance(data['colors'], set), type(data['colors'])
assert data['colors'] == {'red', 'green', 'blue'}, data['colors']
PY
