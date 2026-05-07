#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-safe-load-merge-key-overrides-base
# @title: PyYAML safe_load merge key lets explicit keys override merged base
# @description: Loads a YAML mapping that uses the << merge key to inherit from an anchored base while overriding one of its keys, and asserts the explicit override wins over the merged value while other inherited keys are preserved.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, merge-key
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
base: &base
  color: red
  size: small
  shape: square
override:
  <<: *base
  color: blue
"""
data = yaml.safe_load(doc)
ov = data['override']
assert ov['color'] == 'blue', ov  # explicit override
assert ov['size'] == 'small', ov  # inherited
assert ov['shape'] == 'square', ov  # inherited
PY
