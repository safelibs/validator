#!/usr/bin/env bash
# @testcase: usage-python3-lxml-iterparse-start-end-events
# @title: lxml iterparse start and end events
# @description: Parses XML via lxml.etree.iterparse subscribed to both start and end events and verifies the exact ordered event stream of (event,tag) tuples produced for a small fixture.
# @timeout: 120
# @tags: usage, xml, python, sax
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-iterparse-start-end-events"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' >"$tmpdir/out"
from io import BytesIO
from lxml import etree
src = BytesIO(b'<root><a/><b><c/></b></root>')
events = []
for ev, el in etree.iterparse(src, events=('start', 'end')):
    events.append("%s:%s" % (ev, el.tag))
print("|".join(events))
PY

expected='start:root|start:a|end:a|start:b|start:c|end:c|end:b|end:root'
got=$(tr -d '\n' <"$tmpdir/out")
[[ "$got" == "$expected" ]] || {
  printf 'iterparse event stream mismatch:\nexpected: %s\nactual:   %s\n' "$expected" "$got" >&2
  exit 1
}
