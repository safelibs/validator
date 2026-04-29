#!/usr/bin/env bash
# @testcase: usage-python3-yaml-sorted-dump
# @title: PyYAML sorted dump
# @description: Dumps sorted keys with PyYAML and verifies deterministic key order.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-sorted-dump"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

dumped = yaml.safe_dump({'b': 2, 'a': 1}, sort_keys=True)
assert dumped.splitlines()[0] == 'a: 1'
print(dumped.splitlines()[0])
PY
