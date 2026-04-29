#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-roundtrip-list
# @title: PyYAML list round trip
# @description: Dumps and reloads a YAML list with PyYAML and verifies the values survive round trip.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-roundtrip-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

payload = ['alpha', 'beta', 'gamma']
dumped = yaml.safe_dump(payload)
assert yaml.safe_load(dumped) == payload
print(len(payload))
PY
