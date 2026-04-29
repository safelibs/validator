#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-ordered-keys
# @title: PyYAML safe load ordered keys
# @description: Loads a mapping with safe_load and verifies the insertion order of the decoded keys.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-ordered-keys"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('alpha: 1\nbeta: 2\ngamma: 3\n')
print(','.join(value.keys()))
PYCASE
validator_assert_contains "$tmpdir/out" 'alpha,beta,gamma'
