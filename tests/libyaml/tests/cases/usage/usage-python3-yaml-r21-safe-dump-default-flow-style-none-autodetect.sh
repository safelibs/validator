#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-dump-default-flow-style-none-autodetect
# @title: PyYAML safe_dump default_flow_style=None auto-selects block style for a nested mapping
# @description: Calls yaml.safe_dump on a nested dict-of-dict with default_flow_style=None and asserts the output uses block-mapping form (key:\\n  inner: value) rather than inline {curly} flow — pinning libyaml's autodetect dumping mode through python3-yaml.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, default-flow-style, autodetect, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = {'outer': {'inner_deep': {'leaf_a': 1, 'leaf_b': 2}, 'inner_b': 7}}
out = yaml.safe_dump(data, default_flow_style=None)
# Auto-detect should choose block style at outer levels for nested mappings,
# so 'outer:' must end its line (block form) rather than be inline flow.
lines = out.splitlines()
outer_line = next(line for line in lines if line.startswith('outer:'))
assert outer_line.rstrip() == 'outer:', repr(outer_line)
# The leaf-mapping {leaf_a: 1, leaf_b: 2} is flow-styled at the deepest level.
assert '{leaf_a:' in out, out
PY
