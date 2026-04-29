#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-dump-flow-style
# @title: PyYAML safe dump flow style
# @description: Dumps a sequence with default_flow_style enabled in PyYAML and verifies the inline flow array is emitted.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-dump-flow-style"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
text = yaml.safe_dump({'items': [1, 2, 3]}, default_flow_style=True)
print(text, end='')
PYCASE
validator_assert_contains "$tmpdir/out" '[1, 2, 3]'
