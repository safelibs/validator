#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-safe-dump-default-flow-style-false-block
# @title: PyYAML safe_dump default_flow_style=False produces block-style sequences and mappings
# @description: Dumps a mapping whose value is a small list with default_flow_style=False and asserts the output uses block style (no curly or square brackets, one element per line with leading dashes), distinguishing the explicit block-style mode from the autodetect default.
# @timeout: 60
# @tags: usage, python3-yaml, safedump, default-flow-style
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'items': [1, 2, 3]}
out = yaml.safe_dump(src, default_flow_style=False)
# Block form must contain "- " line prefixes and must NOT contain flow brackets.
assert '- 1\n' in out and '- 2\n' in out and '- 3\n' in out, out
assert '[' not in out and ']' not in out, out
assert '{' not in out and '}' not in out, out
back = yaml.safe_load(out)
assert back == src, (back, src)
PY
