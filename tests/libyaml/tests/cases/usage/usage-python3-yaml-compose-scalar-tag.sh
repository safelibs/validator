#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-scalar-tag
# @title: PyYAML compose scalar tag
# @description: Composes a YAML document and verifies the scalar node tag for an integer value.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-scalar-tag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
node = yaml.compose('answer: 42\n')
_key_node, value_node = node.value[0]
print(value_node.tag)
PYCASE
validator_assert_contains "$tmpdir/out" 'int'
