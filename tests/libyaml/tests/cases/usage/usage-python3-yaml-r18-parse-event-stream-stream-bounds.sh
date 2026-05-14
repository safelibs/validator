#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-parse-event-stream-stream-bounds
# @title: PyYAML yaml.parse emits StreamStartEvent first and StreamEndEvent last
# @description: Iterates yaml.parse over a small sequence document and asserts the first event is a StreamStartEvent and the last is a StreamEndEvent — pinning the high-level event-stream boundary contract.
# @timeout: 60
# @tags: usage, python3-yaml, parse, events, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
from yaml.events import StreamStartEvent, StreamEndEvent

events = list(yaml.parse('- 1\n- 2\n'))
assert events, events
assert isinstance(events[0], StreamStartEvent), type(events[0])
assert isinstance(events[-1], StreamEndEvent), type(events[-1])
PY
