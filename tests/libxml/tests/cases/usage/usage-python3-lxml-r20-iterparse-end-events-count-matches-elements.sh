#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r20-iterparse-end-events-count-matches-elements
# @title: lxml iterparse with events=('end',) yields one event per element node in document order
# @description: Feeds a three-deep XML document into etree.iterparse with events=('end',), collects the tag of each emitted event in order, and asserts the list equals ['leaf', 'mid', 'root'] — pinning the libxml2 SAX-driven iterparse end-event ordering through lxml.
# @timeout: 60
# @tags: usage, xml, python, iterparse, end-events, r20
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root><mid><leaf/></mid></root>
XML

python3 - "$tmpdir/in.xml" <<'PY'
import sys
from lxml import etree

tags = []
for event, elem in etree.iterparse(sys.argv[1], events=('end',)):
    tags.append(elem.tag)

assert tags == ['leaf', 'mid', 'root'], tags
PY
