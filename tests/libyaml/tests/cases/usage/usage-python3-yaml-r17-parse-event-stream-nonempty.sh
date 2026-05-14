#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-parse-event-stream-nonempty
# @title: PyYAML yaml.parse over a simple document yields a non-empty event stream including a MappingStartEvent
# @description: Feeds yaml.parse a small mapping document, materializes the event iterator into a list, and asserts the resulting events count is at least 5 and includes a MappingStartEvent — exercising the SAX-style parser entry point on top of libyaml.
# @timeout: 60
# @tags: usage, python3-yaml, parse, events
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

events = list(yaml.parse('a: 1\nb: 2\n'))
assert len(events) >= 5, len(events)
kinds = [type(e).__name__ for e in events]
assert 'MappingStartEvent' in kinds, kinds
assert 'StreamStartEvent' in kinds, kinds
assert 'StreamEndEvent' in kinds, kinds
PY
