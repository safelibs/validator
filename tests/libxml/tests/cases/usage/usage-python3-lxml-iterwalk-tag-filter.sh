#!/usr/bin/env bash
# @testcase: usage-python3-lxml-iterwalk-tag-filter
# @title: lxml iterwalk with tag filter
# @description: Walks an etree with etree.iterwalk filtered to a specific tag, verifies the iterator yields only elements with that tag in document order, and confirms elements with other tag names are skipped.
# @timeout: 180
# @tags: usage, xml, python, iterwalk
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xml = b"""<root>
  <item id='a'/>
  <other id='x'/>
  <group>
    <item id='b'/>
    <item id='c'/>
  </group>
  <other id='y'/>
  <item id='d'/>
</root>"""
root = etree.fromstring(xml)

ids = []
tags = []
for event, element in etree.iterwalk(root, events=("end",), tag="item"):
    tags.append(element.tag)
    ids.append(element.get("id"))

assert tags == ["item", "item", "item", "item"], tags
assert ids == ["a", "b", "c", "d"], ids

print("ids=" + ",".join(ids))
print("count=" + str(len(ids)))
print("only-item=" + str(set(tags) == {"item"}))
PY

validator_assert_contains "$tmpdir/out" 'ids=a,b,c,d'
validator_assert_contains "$tmpdir/out" 'count=4'
validator_assert_contains "$tmpdir/out" 'only-item=True'
