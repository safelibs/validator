#!/usr/bin/env bash
# @testcase: usage-python3-lxml-iterparse-tag-filter-r8
# @title: lxml iterparse tag filter with element clear
# @description: Drives lxml.etree.iterparse with a tag= filter that selects only end events for <item>, calls Element.clear() after each match to release children, and verifies the collected id attributes plus that the root retains zero children after the streaming pass.
# @timeout: 120
# @tags: usage, xml, python, sax
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<catalog>
  <item id="a"><name>alpha</name></item>
  <item id="b"><name>beta</name></item>
  <item id="c"><name>gamma</name></item>
</catalog>
XML

python3 - "$tmpdir/in.xml" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

ids = []
ctx = etree.iterparse(sys.argv[1], tag='item', events=('end',))
root = None
for ev, el in ctx:
    assert ev == 'end'
    assert el.tag == 'item'
    ids.append(el.get('id'))
    parent = el.getparent()
    parent.remove(el)
    root = parent

print('ids=' + ','.join(ids))
print('root_children=' + str(len(root) if root is not None else -1))
PY

validator_assert_contains "$tmpdir/out" 'ids=a,b,c'
validator_assert_contains "$tmpdir/out" 'root_children=0'
