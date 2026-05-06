#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-compose-literal-block-scalar-style
# @title: PyYAML compose preserves block-literal style on ScalarNode
# @description: Composes a mapping whose value uses the | block-literal style and asserts the resulting ScalarNode has style attribute equal to '|', distinguishing it from folded '>' or default plain scalars.
# @timeout: 60
# @tags: usage, python3-yaml, compose, style
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "body: |\n  line1\n  line2\n"
node = yaml.compose(doc)
assert isinstance(node, yaml.MappingNode), type(node)
pairs = {k.value: (v.value, v.style) for k, v in node.value}
value, style = pairs['body']
assert style == '|', f'expected style "|" got {style!r}'
assert value == 'line1\nline2\n', repr(value)
PY
