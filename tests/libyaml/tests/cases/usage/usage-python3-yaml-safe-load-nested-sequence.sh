#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-nested-sequence
# @title: PyYAML safe load nested sequence
# @description: Exercises pyyaml safe load nested sequence through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-nested-sequence"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

value = yaml.safe_load('root:\n  - [1, 2]\n  - [3, 4]\n')
assert value == {'root': [[1, 2], [3, 4]]}
print(value['root'][1][1])
PY
