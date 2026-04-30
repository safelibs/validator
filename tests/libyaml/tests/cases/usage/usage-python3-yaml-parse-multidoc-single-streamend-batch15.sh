#!/usr/bin/env bash
# @testcase: usage-python3-yaml-parse-multidoc-single-streamend-batch15
# @title: PyYAML parse on a multi-doc stream emits exactly one StreamEndEvent
# @description: Drives yaml.parse against a three-document stream separated by --- and verifies the event sequence has exactly one StreamStartEvent, exactly one StreamEndEvent, and exactly three DocumentStartEvent / DocumentEndEvent pairs interleaved between them.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-parse-multidoc-single-streamend-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml
from yaml.events import (
    DocumentEndEvent,
    DocumentStartEvent,
    ScalarEvent,
    StreamEndEvent,
    StreamStartEvent,
)

case_id = sys.argv[1]
out_path = sys.argv[2]

source = (
    "---\n"
    "doc: one\n"
    "---\n"
    "doc: two\n"
    "---\n"
    "doc: three\n"
)

events = list(yaml.parse(source))

stream_starts = [e for e in events if isinstance(e, StreamStartEvent)]
stream_ends = [e for e in events if isinstance(e, StreamEndEvent)]
doc_starts = [e for e in events if isinstance(e, DocumentStartEvent)]
doc_ends = [e for e in events if isinstance(e, DocumentEndEvent)]

assert len(stream_starts) == 1, len(stream_starts)
assert len(stream_ends) == 1, len(stream_ends)
assert len(doc_starts) == 3, len(doc_starts)
assert len(doc_ends) == 3, len(doc_ends)

# StreamEndEvent must be the very last event.
assert isinstance(events[-1], StreamEndEvent), events[-1]
# StreamStartEvent must be the very first event.
assert isinstance(events[0], StreamStartEvent), events[0]

# Confirm scalar values from each document are visible in the event stream.
scalar_values = [e.value for e in events if isinstance(e, ScalarEvent)]
assert "one" in scalar_values, scalar_values
assert "two" in scalar_values, scalar_values
assert "three" in scalar_values, scalar_values

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"stream_starts={len(stream_starts)}\n")
    fh.write(f"stream_ends={len(stream_ends)}\n")
    fh.write(f"doc_starts={len(doc_starts)}\n")
    fh.write(f"doc_ends={len(doc_ends)}\n")

print("MULTIDOC_PARSE_OK")
PYCASE

validator_assert_contains "$tmpdir/out" "stream_starts=1"
validator_assert_contains "$tmpdir/out" "stream_ends=1"
validator_assert_contains "$tmpdir/out" "doc_starts=3"
validator_assert_contains "$tmpdir/out" "doc_ends=3"
echo "OK"
