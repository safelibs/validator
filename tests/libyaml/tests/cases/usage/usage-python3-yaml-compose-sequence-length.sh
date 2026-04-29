#!/usr/bin/env bash
# @testcase: usage-python3-yaml-compose-sequence-length
# @title: PyYAML compose sequence length
# @description: Composes a YAML sequence node with PyYAML and verifies the resulting node contains the expected number of items.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-compose-sequence-length"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
node = yaml.compose('[1, 2, 3]')
print(len(node.value))
PYCASE
validator_assert_contains "$tmpdir/out" '3'
