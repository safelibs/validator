#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-load-binary-bytes
# @title: PyYAML CSafeLoader binary bytes
# @description: Loads a binary scalar through the C-backed PyYAML loader and verifies the decoded byte string.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-load-binary-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
value = yaml.load('payload: !!binary Zm9v\n', Loader=loader)
print(value['payload'])
PYCASE
validator_assert_contains "$tmpdir/out" "b'foo'"
