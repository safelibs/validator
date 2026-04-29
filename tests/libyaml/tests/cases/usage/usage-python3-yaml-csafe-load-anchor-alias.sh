#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-load-anchor-alias
# @title: PyYAML CSafeLoader anchor alias
# @description: Loads an anchored scalar and its alias through the C-backed PyYAML loader and verifies both keys resolve to the same value.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-load-anchor-alias"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
value = yaml.load('first: &one alpha\nsecond: *one\n', Loader=loader)
print(value['first'], value['second'])
PYCASE
validator_assert_contains "$tmpdir/out" 'alpha alpha'
