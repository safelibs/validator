#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-null-list
# @title: PyYAML safe load null list
# @description: Loads YAML null scalars with safe_load and verifies the decoded Python None values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-null-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('[null, ~, value]\n')
print(value[0] is None, value[1] is None, value[2])
PYCASE
validator_assert_contains "$tmpdir/out" 'True True value'
