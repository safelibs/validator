#!/usr/bin/env bash
# @testcase: usage-python3-yaml-full-load-timestamp
# @title: PyYAML full load timestamp
# @description: Loads a YAML timestamp with full_load and verifies the decoded date value.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-full-load-timestamp"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
value = yaml.full_load('when: 2024-01-02\n')
print(value['when'].isoformat())
PYCASE
validator_assert_contains "$tmpdir/out" '2024-01-02'
