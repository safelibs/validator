#!/usr/bin/env bash
# @testcase: usage-python3-yaml-base-loader-int-string
# @title: PyYAML base loader integer string
# @description: Exercises pyyaml base loader integer string through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-base-loader-int-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

value = yaml.load('count: 7\n', Loader=yaml.BaseLoader)
assert value['count'] == '7'
print(value['count'])
PY
