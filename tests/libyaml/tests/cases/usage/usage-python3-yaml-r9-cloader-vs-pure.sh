#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-cloader-vs-pure
# @title: PyYAML CSafeLoader and SafeLoader produce identical output
# @description: Loads the same YAML document with yaml.SafeLoader and yaml.CSafeLoader (when available) and asserts the parsed structures are equal.
# @timeout: 60
# @tags: usage, python3-yaml, libyaml
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import yaml
text = """name: demo
items: [1, 2, 3]
nested:
  a: 1.5
  b: true
  c: null
"""
pure = yaml.load(text, Loader=yaml.SafeLoader)
assert hasattr(yaml, 'CSafeLoader'), 'CSafeLoader missing — libyaml not built'
fast = yaml.load(text, Loader=yaml.CSafeLoader)
assert pure == fast, (pure, fast)
PY
