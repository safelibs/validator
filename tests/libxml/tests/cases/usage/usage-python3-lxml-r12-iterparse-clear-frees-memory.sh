#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r12-iterparse-clear-frees-memory
# @title: lxml.etree.iterparse end-event handler can elem.clear() each item without losing root tag
# @description: Streams a small XML document with iterparse, calls clear() on each end-event element, and asserts every item tag was visited and the root tag is still recoverable from the parser, exercising the documented streaming-with-clear pattern.
# @timeout: 60
# @tags: usage, xml, python, iterparse
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root>
  <item id="a">one</item>
  <item id="b">two</item>
  <item id="c">three</item>
</root>
XML

python3 - "$tmpdir/in.xml" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

path = sys.argv[1]
ids = []
context = etree.iterparse(path, events=('end',), tag='item')
for _, elem in context:
    ids.append(elem.get('id'))
    elem.clear()
root = context.root
print('ids=' + ','.join(ids))
print('root_tag=' + root.tag)
print('remaining_children=' + str(len(list(root))))
PY

validator_assert_contains "$tmpdir/out" 'ids=a,b,c'
validator_assert_contains "$tmpdir/out" 'root_tag=root'
validator_assert_contains "$tmpdir/out" 'remaining_children=3'
