#!/usr/bin/env bash
# @testcase: usage-python3-lxml-sax-handler-integration
# @title: lxml SAX handler integration
# @description: Drives a custom xml.sax.ContentHandler from an in-memory lxml etree using lxml.sax.saxify, asserts the handler observes the expected ordered sequence of startElement / characters / endElement callbacks, and verifies element nesting via depth tracking.
# @timeout: 180
# @tags: usage, xml, python, sax
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from xml.sax.handler import ContentHandler
from lxml import etree, sax

class Recorder(ContentHandler):
    def __init__(self):
        super().__init__()
        self.events = []
        self.depth = 0
        self.max_depth = 0

    def startElementNS(self, name, qname, attrs):
        self.depth += 1
        self.max_depth = max(self.max_depth, self.depth)
        self.events.append("start:" + name[1])

    def endElementNS(self, name, qname):
        self.events.append("end:" + name[1])
        self.depth -= 1

    def characters(self, content):
        text = content.strip()
        if text:
            self.events.append("chars:" + text)

root = etree.fromstring(b"<root><a>x</a><b><c>y</c></b></root>")
handler = Recorder()
sax.saxify(root, handler)

expected = [
    "start:root",
    "start:a", "chars:x", "end:a",
    "start:b",
    "start:c", "chars:y", "end:c",
    "end:b",
    "end:root",
]
assert handler.events == expected, handler.events
assert handler.max_depth == 3, handler.max_depth

print("events=" + "|".join(handler.events))
print("max-depth=" + str(handler.max_depth))
print("count=" + str(len(handler.events)))
PY

validator_assert_contains "$tmpdir/out" 'events=start:root|start:a|chars:x|end:a|start:b|start:c|chars:y|end:c|end:b|end:root'
validator_assert_contains "$tmpdir/out" 'max-depth=3'
validator_assert_contains "$tmpdir/out" 'count=10'
