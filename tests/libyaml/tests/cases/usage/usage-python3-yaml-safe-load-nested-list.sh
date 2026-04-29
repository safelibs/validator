#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-nested-list
# @title: PyYAML safe load nested list
# @description: Loads a nested YAML sequence with PyYAML and verifies the inner list element values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-nested-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('matrix:\n  - [1, 2]\n  - [3, 4]\n')
print(value['matrix'][1][0], value['matrix'][1][1])
PYCASE
validator_assert_contains "$tmpdir/out" '3 4'
