#!/usr/bin/env bash
# @testcase: usage-python3-yaml-parse-events
# @title: PyYAML parse events
# @description: Parses YAML events with PyYAML and verifies scalar events are emitted for values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-parse-events"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" | tee "$tmpdir/out"
import datetime
import sys
import yaml
from yaml.events import ScalarEvent
from yaml.tokens import ScalarToken

case_id = sys.argv[1]

events = list(yaml.parse('name: alpha\n'))
assert any(isinstance(event, ScalarEvent) and event.value == 'alpha' for event in events)
print('events', len(events))
PY
