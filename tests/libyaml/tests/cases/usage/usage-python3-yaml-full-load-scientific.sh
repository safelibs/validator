#!/usr/bin/env bash
# @testcase: usage-python3-yaml-full-load-scientific
# @title: PyYAML full load scientific number
# @description: Exercises pyyaml full load scientific number through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-full-load-scientific"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

value = yaml.full_load('number: 1.0e+3\n')
parsed = value['number']
assert str(parsed).lower() in {'1000.0', '1000', '1.0e+3'}
print(parsed)
PY
