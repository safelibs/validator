#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-safe-load-comment-ignored
# @title: PyYAML safe_load drops # comments from the loaded document body
# @description: Loads a YAML document with a # tail comment on a mapping value line via yaml.safe_load and asserts the resulting Python value equals the bare scalar without any '#' character, pinning the libyaml comment-stripping path.
# @timeout: 60
# @tags: usage, python3-yaml, comment, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
greeting: hello   # the friendly word
"""
data = yaml.safe_load(doc)
assert data == {'greeting': 'hello'}, data
PY
