#!/usr/bin/env bash
# @testcase: usage-python3-yaml-flow-style
# @title: PyYAML flow style dump
# @description: Dumps a mapping in flow style through PyYAML and checks serialized braces.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-flow-style"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

dumped = yaml.safe_dump({'alpha': 1, 'beta': 2}, default_flow_style=True)
assert '{' in dumped and 'alpha' in dumped
print(dumped.strip())
PY
