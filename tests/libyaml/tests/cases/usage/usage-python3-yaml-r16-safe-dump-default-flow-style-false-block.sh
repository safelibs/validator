#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-safe-dump-default-flow-style-false-block
# @title: PyYAML safe_dump default_flow_style=False emits a block-style mapping (one key per line)
# @description: Dumps a small mapping with default_flow_style=False and asserts the output contains a newline-per-key block-style layout, with no curly-brace flow markers and the expected 'key: value' line for each entry.
# @timeout: 60
# @tags: usage, python3-yaml, safedump, block-style
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

text = yaml.safe_dump({'a': 1, 'b': 2, 'c': 3}, default_flow_style=False)
# Block-style mapping: no curly braces.
assert '{' not in text, text
assert '}' not in text, text
lines = text.strip().splitlines()
assert len(lines) == 3, lines
assert 'a: 1' in lines
assert 'b: 2' in lines
assert 'c: 3' in lines
PY
