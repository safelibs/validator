#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-flow-set-batch11
# @title: PyYAML CSafeLoader flow set
# @description: Loads a YAML set with CSafeLoader through PyYAML.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-flow-set-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

data = yaml.load('!!set {alpha: null, beta: null}', Loader=yaml.CSafeLoader)
assert data == {'alpha', 'beta'}
print(sorted(data))
PYCASE
