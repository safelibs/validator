#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-multiline-scalar-batch13
# @title: PyYAML compose with multiline literal scalar value
# @description: Composes a mapping whose value is a literal block scalar and verifies the resulting ScalarNode preserves the multiline content with a trailing newline.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-multiline-scalar-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" | tee "$tmpdir/out"
import sys
import yaml
from yaml.nodes import MappingNode, ScalarNode

case_id = sys.argv[1]

doc = "message: |\n  line one\n  line two\n  line three\n"
node = yaml.compose(doc)

assert isinstance(node, MappingNode), node
key, value = node.value[0]
assert isinstance(key, ScalarNode) and key.value == "message", key
assert isinstance(value, ScalarNode), value
assert value.value == "line one\nline two\nline three\n", repr(value.value)
assert value.style == "|", value.style

print("KEY", key.value)
print("LINES", value.value.count("\n"))
print("STYLE", value.style)
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "KEY message"
validator_assert_contains "$tmpdir/out" "LINES 3"
validator_assert_contains "$tmpdir/out" "STYLE |"
echo "OK"
