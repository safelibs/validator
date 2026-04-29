#!/usr/bin/env bash
# @testcase: usage-python3-yaml-base-loader-bool-string
# @title: PyYAML BaseLoader boolean string
# @description: Loads a boolean-like scalar with BaseLoader and verifies it remains a string.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-base-loader-bool-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

data = yaml.load('flag: true\n', Loader=yaml.BaseLoader)
assert data['flag'] == 'true'
print(data['flag'])
PY
