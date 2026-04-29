#!/usr/bin/env bash
# @testcase: usage-python3-yaml-binary-scalar
# @title: PyYAML binary scalar decoding
# @description: Runs PyYAML safe_load on a binary scalar and verifies the decoded byte payload.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
import yaml

decoded = yaml.safe_load("payload: !!binary dmFsaWRhdG9yLWJpbmFyeQ==\n")["payload"]
assert decoded == b"validator-binary"
print(len(decoded))
PY

validator_assert_contains "$tmpdir/out" '16'
