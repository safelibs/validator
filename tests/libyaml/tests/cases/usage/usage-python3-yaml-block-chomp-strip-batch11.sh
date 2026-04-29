#!/usr/bin/env bash
# @testcase: usage-python3-yaml-block-chomp-strip-batch11
# @title: PyYAML block chomp strip
# @description: Loads a literal block scalar with strip chomping through PyYAML.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-block-chomp-strip-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

data = yaml.safe_load('value: |-\n  alpha\n  beta\n')
assert data['value'] == 'alpha\nbeta'
print(data['value'])
PYCASE
