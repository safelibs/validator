#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-sequence
# @title: PyYAML CSafeLoader sequence
# @description: Loads a YAML sequence through CSafeLoader and verifies list ordering.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-sequence"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
data = yaml.load('- 1\n- 2\n', Loader=loader)
assert data == [1, 2]
print(data)
PY
