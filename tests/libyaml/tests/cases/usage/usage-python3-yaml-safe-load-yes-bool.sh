#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-yes-bool
# @title: PyYAML safe load yes bool
# @description: Loads a YAML yes scalar with PyYAML and verifies the resolved boolean value is true.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-yes-bool"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('flag: yes\n')
print(value['flag'])
PYCASE
validator_assert_contains "$tmpdir/out" 'True'
