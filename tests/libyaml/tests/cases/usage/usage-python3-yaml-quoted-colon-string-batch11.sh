#!/usr/bin/env bash
# @testcase: usage-python3-yaml-quoted-colon-string-batch11
# @title: PyYAML quoted colon string
# @description: Loads a quoted scalar containing a colon through PyYAML.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-quoted-colon-string-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

data = yaml.safe_load('value: "alpha: beta"')
assert data['value'] == 'alpha: beta'
print(data['value'])
PYCASE
