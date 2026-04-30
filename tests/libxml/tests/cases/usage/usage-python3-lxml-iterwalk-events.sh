#!/usr/bin/env bash
# @testcase: usage-python3-lxml-iterwalk-events
# @title: lxml iterwalk start and end events
# @description: Walks an in-memory etree with etree.iterwalk subscribing to start and end events, collects the ordered sequence of (event, tag) pairs, and verifies the expected nesting order including a nested element appearing between its parent's start and end events.
# @timeout: 180
# @tags: usage, xml, python, iterwalk
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-iterwalk-events"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.XML(b"<root><a><b/></a><c/></root>")
events = []
for event, element in etree.iterwalk(root, events=("start", "end")):
    events.append(event + ":" + element.tag)

expected = [
    "start:root",
    "start:a",
    "start:b",
    "end:b",
    "end:a",
    "start:c",
    "end:c",
    "end:root",
]
assert events == expected, events

print("events=" + ",".join(events))
print("count=" + str(len(events)))
PY

validator_assert_contains "$tmpdir/out" 'events=start:root,start:a,start:b,end:b,end:a,start:c,end:c,end:root'
validator_assert_contains "$tmpdir/out" 'count=8'
