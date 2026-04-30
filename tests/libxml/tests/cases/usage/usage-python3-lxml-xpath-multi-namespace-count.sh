#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpath-multi-namespace-count
# @title: lxml XPath multi-namespace count
# @description: Evaluates XPath expressions over a document that mixes two distinct namespaces and verifies the exact element counts returned for each namespace prefix binding.
# @timeout: 180
# @tags: usage, xml, python, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.XML(b"""<root xmlns:a="urn:a" xmlns:b="urn:b">
  <a:item id="1">alpha</a:item>
  <a:item id="2">beta</a:item>
  <b:item id="3">gamma</b:item>
  <a:item id="4">delta</a:item>
  <b:item id="5">epsilon</b:item>
</root>""")
ns = {"a": "urn:a", "b": "urn:b"}

a_items = doc.xpath("//a:item", namespaces=ns)
b_items = doc.xpath("//b:item", namespaces=ns)
all_items = doc.xpath("//*[local-name()='item']")

assert len(a_items) == 3, len(a_items)
assert len(b_items) == 2, len(b_items)
assert len(all_items) == 5, len(all_items)

a_ids = sorted(int(e.get("id")) for e in a_items)
b_ids = sorted(int(e.get("id")) for e in b_items)
assert a_ids == [1, 2, 4], a_ids
assert b_ids == [3, 5], b_ids

print("a-count=" + str(len(a_items)))
print("b-count=" + str(len(b_items)))
print("a-ids=" + ",".join(str(i) for i in a_ids))
print("b-ids=" + ",".join(str(i) for i in b_ids))
PY

validator_assert_contains "$tmpdir/out" 'a-count=3'
validator_assert_contains "$tmpdir/out" 'b-count=2'
validator_assert_contains "$tmpdir/out" 'a-ids=1,2,4'
validator_assert_contains "$tmpdir/out" 'b-ids=3,5'
