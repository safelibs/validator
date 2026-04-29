#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-dump-default-style
# @title: PyYAML safe dump default style
# @description: Dumps a nested structure with safe_dump and verifies the default block-style list formatting.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-dump-default-style"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
text = yaml.safe_dump({'items': [1, 2]}, sort_keys=False)
print(text, end='')
PYCASE
validator_assert_contains "$tmpdir/out" 'items:'
validator_assert_contains "$tmpdir/out" '- 1'
