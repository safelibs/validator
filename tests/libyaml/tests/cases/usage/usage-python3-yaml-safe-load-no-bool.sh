#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-no-bool
# @title: PyYAML safe load no bool
# @description: Loads a YAML no scalar with PyYAML and verifies the resolved boolean value is false.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-no-bool"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('flag: no\n')
print(value['flag'])
PYCASE
validator_assert_contains "$tmpdir/out" 'False'
