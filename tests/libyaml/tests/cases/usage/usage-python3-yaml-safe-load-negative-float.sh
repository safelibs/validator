#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-negative-float
# @title: PyYAML safe load negative float
# @description: Loads a negative floating-point scalar with PyYAML and verifies the parsed numeric value.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-negative-float"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('value: -2.5\n')
print(value['value'])
PYCASE
validator_assert_contains "$tmpdir/out" '-2.5'
