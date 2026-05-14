#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r17-iterparse-end-event-count
# @title: lxml etree.iterparse with end events yields one event per closing tag in the stream
# @description: Streams a small XML document through etree.iterparse with events=('end',), collects the tag names of each emitted end event, and asserts the count and ordering match the document's closing-tag sequence — exercising libxml2's incremental parser through lxml.
# @timeout: 60
# @tags: usage, xml, python, iterparse
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root><a><b/></a><c/></root>
XML

python3 - "$tmpdir/in.xml" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree
ends = []
for event, el in etree.iterparse(sys.argv[1], events=('end',)):
    ends.append(el.tag)
print('count=' + str(len(ends)))
print('order=' + ','.join(ends))
PY

validator_assert_contains "$tmpdir/out" 'count=4'
validator_assert_contains "$tmpdir/out" 'order=b,a,c,root'
