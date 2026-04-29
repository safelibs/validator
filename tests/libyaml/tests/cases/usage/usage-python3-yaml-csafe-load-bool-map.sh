#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-load-bool-map
# @title: PyYAML CSafeLoader bool map
# @description: Loads booleans with CSafeLoader and verifies the decoded truth values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-load-bool-map"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
value = yaml.load('alpha: true\nbeta: false\n', Loader=loader)
print(value['alpha'], value['beta'])
PYCASE
validator_assert_contains "$tmpdir/out" 'True False'
