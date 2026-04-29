#!/usr/bin/env bash
# @testcase: usage-python3-yaml-parse-event-order-batch11
# @title: PyYAML parse event order
# @description: Parses YAML events and checks stream and sequence events.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-parse-event-order-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id"
import re
import sys
import yaml

case_id = sys.argv[1]

events = [type(event).__name__ for event in yaml.parse('- a\n- b\n')]
assert events[0] == 'StreamStartEvent'
assert 'SequenceStartEvent' in events
print(','.join(events))
PYCASE
