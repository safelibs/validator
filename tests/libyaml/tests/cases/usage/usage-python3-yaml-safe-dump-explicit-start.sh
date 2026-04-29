#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-dump-explicit-start
# @title: PyYAML safe dump explicit start
# @description: Dumps a document with an explicit YAML start marker and verifies the document header is emitted.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-dump-explicit-start"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
print(yaml.safe_dump({'name': 'validator'}, explicit_start=True), end='')
PYCASE
validator_assert_contains "$tmpdir/out" '---'
