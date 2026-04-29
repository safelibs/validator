#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-hex-int
# @title: PyYAML safe load hex int
# @description: Loads a hexadecimal integer with PyYAML and verifies the parsed decimal integer value.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-hex-int"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.safe_load('answer: 0x10\n')
print(value['answer'])
PYCASE
validator_assert_contains "$tmpdir/out" '16'
