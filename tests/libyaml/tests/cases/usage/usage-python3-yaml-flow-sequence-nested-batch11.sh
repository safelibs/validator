#!/usr/bin/env bash
# @testcase: usage-python3-yaml-flow-sequence-nested-batch11
# @title: PyYAML nested flow sequence
# @description: Loads a nested flow sequence through PyYAML safe_load.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-flow-sequence-nested-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

data = yaml.safe_load('root: [[1, 2], [3, 4]]')
assert data['root'][1][0] == 3
print(data['root'])
PYCASE
