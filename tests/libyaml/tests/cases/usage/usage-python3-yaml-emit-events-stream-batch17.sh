#!/usr/bin/env bash
# @testcase: usage-python3-yaml-emit-events-stream-batch17
# @title: PyYAML yaml.emit produces YAML from a hand-built event sequence
# @description: Builds a yaml.events sequence (StreamStart, DocumentStart, MappingStart, two ScalarEvent pairs, MappingEnd, DocumentEnd, StreamEnd) and feeds it to yaml.emit, then verifies the emitted text parses back into the expected mapping with both keys and matching scalar values.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-emit-events-stream-batch17"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml
from yaml.events import (
    StreamStartEvent,
    StreamEndEvent,
    DocumentStartEvent,
    DocumentEndEvent,
    MappingStartEvent,
    MappingEndEvent,
    ScalarEvent,
)

case_id = sys.argv[1]
dst = sys.argv[2]

events = [
    StreamStartEvent(encoding="utf-8"),
    DocumentStartEvent(explicit=False),
    MappingStartEvent(anchor=None, tag=None, implicit=True, flow_style=False),
    ScalarEvent(anchor=None, tag=None, implicit=(True, False), value="title"),
    ScalarEvent(anchor=None, tag=None, implicit=(True, False), value="hand-built"),
    ScalarEvent(anchor=None, tag=None, implicit=(True, False), value="weight"),
    ScalarEvent(anchor=None, tag=None, implicit=(True, False), value="42"),
    MappingEndEvent(),
    DocumentEndEvent(explicit=False),
    StreamEndEvent(),
]

text = yaml.emit(events)
assert "title:" in text, text
assert "hand-built" in text, text
assert "weight:" in text, text
assert "42" in text, text

# The emitted text must be parseable.
loaded = yaml.safe_load(text)
# "42" is implicitly resolved to int by SafeLoader.
assert loaded == {"title": "hand-built", "weight": 42}, loaded

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "title:"
validator_assert_contains "$tmpdir/out.yaml" "hand-built"
validator_assert_contains "$tmpdir/out.yaml" "weight:"
echo "OK"
