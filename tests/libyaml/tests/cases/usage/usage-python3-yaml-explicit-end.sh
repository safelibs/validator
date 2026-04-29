#!/usr/bin/env bash
# @testcase: usage-python3-yaml-explicit-end
# @title: PyYAML explicit end marker
# @description: Dumps YAML with an explicit end marker and verifies the document terminator is present.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-explicit-end"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

dumped = yaml.safe_dump({'alpha': 1}, explicit_end=True)
assert dumped.endswith('...\n')
print(dumped.splitlines()[-1])
PY
