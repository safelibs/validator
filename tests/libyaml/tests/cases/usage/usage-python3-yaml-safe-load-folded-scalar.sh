#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-folded-scalar
# @title: PyYAML safe load folded scalar
# @description: Loads a folded block scalar with PyYAML and verifies line folding into a single space-separated string.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-folded-scalar"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('message: >\n  alpha\n  beta\n')
print(value['message'].strip())
PYCASE
validator_assert_contains "$tmpdir/out" 'alpha beta'
