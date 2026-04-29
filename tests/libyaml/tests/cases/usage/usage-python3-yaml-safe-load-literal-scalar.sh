#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-literal-scalar
# @title: PyYAML safe load literal scalar
# @description: Loads a literal block scalar with PyYAML and verifies that newline characters remain in the resulting string.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-literal-scalar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('message: |\n  alpha\n  beta\n')
print(repr(value['message']))
PYCASE
validator_assert_contains "$tmpdir/out" "\\n"
