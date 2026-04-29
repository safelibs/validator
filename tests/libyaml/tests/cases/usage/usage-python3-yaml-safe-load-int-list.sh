#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-int-list
# @title: PyYAML safe load integer list
# @description: Exercises pyyaml safe load integer list through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-int-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

value = yaml.safe_load('- 1\n- 2\n- 3\n')
assert value == [1, 2, 3]
print(sum(value))
PY
