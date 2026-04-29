#!/usr/bin/env bash
# @testcase: usage-python3-yaml-explicit-start
# @title: PyYAML explicit document start
# @description: Dumps YAML with an explicit start marker and verifies serialized output.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-explicit-start"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

dumped = yaml.safe_dump({'alpha': 1}, explicit_start=True)
assert dumped.startswith('---')
print(dumped.splitlines()[0])
PY
