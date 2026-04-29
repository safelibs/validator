#!/usr/bin/env bash
# @testcase: usage-python3-yaml-full-loader-bool
# @title: PyYAML FullLoader boolean
# @description: Loads a boolean scalar through FullLoader and verifies it becomes a Python bool.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-full-loader-bool"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

data = yaml.load('flag: true\n', Loader=yaml.FullLoader)
assert data['flag'] is True
print(data['flag'])
PY
