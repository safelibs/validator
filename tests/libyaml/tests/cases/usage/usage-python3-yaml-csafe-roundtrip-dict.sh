#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-roundtrip-dict
# @title: PyYAML CSafe round trip dict
# @description: Exercises pyyaml csafe round trip dict through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-roundtrip-dict"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

loader = getattr(yaml, 'CSafeLoader', yaml.SafeLoader)
dumper = getattr(yaml, 'CSafeDumper', yaml.SafeDumper)
text = yaml.dump({'name': 'alpha', 'count': 2}, Dumper=dumper, sort_keys=True)
value = yaml.load(text, Loader=loader)
assert value == {'count': 2, 'name': 'alpha'}
print(value['name'], value['count'])
PY
