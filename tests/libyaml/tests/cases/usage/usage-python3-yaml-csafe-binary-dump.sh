#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-binary-dump
# @title: PyYAML CSafeDumper binary
# @description: Dumps bytes through CSafeDumper and verifies a binary scalar can be loaded.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-binary-dump"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

dumper = getattr(yaml, 'CSafeDumper', yaml.SafeDumper)
loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
dumped = yaml.dump({'payload': b'abc'}, Dumper=dumper)
data = yaml.load(dumped, Loader=loader)
assert data['payload'] == b'abc'
print('binary', len(data['payload']))
PY
