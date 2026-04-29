#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-float-inf
# @title: PyYAML safe load float inf
# @description: Loads an infinite floating-point scalar with PyYAML and verifies the parsed value is infinite.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-float-inf"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import math
import yaml
value = yaml.safe_load('answer: .inf\n')
print(math.isinf(value['answer']))
PYCASE
validator_assert_contains "$tmpdir/out" 'True'
