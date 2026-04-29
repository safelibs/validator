#!/usr/bin/env bash
# @testcase: usage-python3-yaml-parse-mapping-start
# @title: PyYAML parse mapping start
# @description: Exercises pyyaml parse mapping start through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-parse-mapping-start"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id"
import sys
import yaml
from yaml.events import MappingStartEvent, ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

events = list(yaml.parse('name: alpha\n'))
assert any(isinstance(event, MappingStartEvent) for event in events)
print(sum(1 for event in events if isinstance(event, MappingStartEvent)))
PY
