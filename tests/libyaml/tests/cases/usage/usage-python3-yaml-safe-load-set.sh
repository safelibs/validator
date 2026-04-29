#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-set
# @title: PyYAML safe load set
# @description: Loads a YAML set with safe_load and verifies the decoded set members.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-set"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('items: !!set {alpha: null, beta: null}\n')
print(','.join(sorted(value['items'])))
PYCASE
validator_assert_contains "$tmpdir/out" 'alpha,beta'
