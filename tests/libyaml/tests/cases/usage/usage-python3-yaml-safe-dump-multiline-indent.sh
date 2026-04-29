#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-dump-multiline-indent
# @title: PyYAML safe dump multiline indent
# @description: Dumps a nested mapping with indent=4 in PyYAML and verifies the nested key is emitted with the configured indentation.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-dump-multiline-indent"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
text = yaml.safe_dump({'tree': {'leaf': 'value'}}, indent=4)
print(text, end='')
PYCASE
validator_assert_contains "$tmpdir/out" '    leaf: value'
