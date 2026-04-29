#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-flow-mapping
# @title: PyYAML safe load flow mapping
# @description: Loads a flow-style YAML mapping with PyYAML and verifies the resolved key values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-flow-mapping"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('{alpha: 1, beta: 2}')
print(value['alpha'], value['beta'])
PYCASE
validator_assert_contains "$tmpdir/out" '1 2'
