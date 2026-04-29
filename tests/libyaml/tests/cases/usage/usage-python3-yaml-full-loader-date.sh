#!/usr/bin/env bash
# @testcase: usage-python3-yaml-full-loader-date
# @title: PyYAML FullLoader date
# @description: Loads a YAML timestamp with FullLoader and verifies date parsing.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-full-loader-date"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

data = yaml.load('day: 2024-01-02\n', Loader=yaml.FullLoader)
assert data['day'] == datetime.date(2024, 1, 2)
print(data['day'].isoformat())
PY
