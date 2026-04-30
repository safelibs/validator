#!/usr/bin/env bash
# @testcase: usage-python3-yaml-parse-events-stream
# @title: PyYAML parse event stream contains expected event types
# @description: Drives yaml.parse against a small mapping document and verifies the stream begins with StreamStartEvent, contains MappingStartEvent and ScalarEvent values, and ends with StreamEndEvent.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
import yaml
from yaml.events import (
    DocumentEndEvent,
    DocumentStartEvent,
    MappingEndEvent,
    MappingStartEvent,
    ScalarEvent,
    StreamEndEvent,
    StreamStartEvent,
)

source = "name: alpha\ncount: 3\n"
events = list(yaml.parse(source))

# Stream framing
assert isinstance(events[0], StreamStartEvent), events[0]
assert isinstance(events[-1], StreamEndEvent), events[-1]

# Document framing exists exactly once.
doc_starts = [e for e in events if isinstance(e, DocumentStartEvent)]
doc_ends = [e for e in events if isinstance(e, DocumentEndEvent)]
assert len(doc_starts) == 1, len(doc_starts)
assert len(doc_ends) == 1, len(doc_ends)

# Mapping framing
map_starts = [e for e in events if isinstance(e, MappingStartEvent)]
map_ends = [e for e in events if isinstance(e, MappingEndEvent)]
assert len(map_starts) == 1, len(map_starts)
assert len(map_ends) == 1, len(map_ends)

# Scalar values: keys and values both come through as ScalarEvent.
scalar_values = [e.value for e in events if isinstance(e, ScalarEvent)]
assert scalar_values == ["name", "alpha", "count", "3"], scalar_values

print("PARSE_OK", len(events))
PY

validator_assert_contains "$tmpdir/out" 'PARSE_OK'
