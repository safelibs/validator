#!/usr/bin/env bash
# @testcase: usage-python3-yaml-base-loader-null-string
# @title: PyYAML base loader null string
# @description: Loads a YAML null scalar with the base loader and verifies it remains a string value.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-base-loader-null-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
loader = getattr(yaml, 'CBaseLoader', yaml.BaseLoader)
value = yaml.load('value: null\n', Loader=loader)
print(value['value'])
PYCASE
validator_assert_contains "$tmpdir/out" 'null'
