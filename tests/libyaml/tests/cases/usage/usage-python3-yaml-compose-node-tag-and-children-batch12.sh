#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-node-tag-and-children-batch12
# @title: PyYAML compose node tag and children
# @description: Composes YAML through PyYAML and verifies the root MappingNode tag plus child ScalarNode tags and values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-node-tag-and-children-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" >"$tmpdir/out"
import sys
import yaml
from yaml.nodes import MappingNode, ScalarNode

case_id = sys.argv[1]

source = "name: alice\nage: 30\n"
node = yaml.compose(source)

assert isinstance(node, MappingNode), type(node).__name__
assert node.tag == "tag:yaml.org,2002:map", node.tag
assert len(node.value) == 2, len(node.value)

key0, val0 = node.value[0]
key1, val1 = node.value[1]
assert isinstance(key0, ScalarNode) and key0.tag == "tag:yaml.org,2002:str"
assert key0.value == "name"
assert val0.value == "alice" and val0.tag == "tag:yaml.org,2002:str"
assert key1.value == "age"
assert val1.value == "30" and val1.tag == "tag:yaml.org,2002:int"

print("ROOT_TAG", node.tag)
print("KEYS", key0.value, key1.value)
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "ROOT_TAG tag:yaml.org,2002:map"
validator_assert_contains "$tmpdir/out" "KEYS name age"
validator_assert_contains "$tmpdir/out" "OK"
echo "OK"
