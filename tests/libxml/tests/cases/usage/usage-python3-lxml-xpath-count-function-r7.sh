#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpath-count-function-r7
# @title: lxml XPath count() over filtered nodeset
# @description: Compiles an XPath expression that counts item elements whose status attribute equals "ok" and verifies the libxml2 XPath engine returns the exact float count and that an unfiltered count() over the full nodeset returns the total cardinality.
# @timeout: 120
# @tags: usage, xml, python, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b"""<root>
  <item status="ok">a</item>
  <item status="bad">b</item>
  <item status="ok">c</item>
  <item status="ok">d</item>
  <item status="bad">e</item>
</root>""")

ok_count = doc.xpath('count(/root/item[@status="ok"])')
total_count = doc.xpath('count(/root/item)')

assert ok_count == 3.0, ok_count
assert total_count == 5.0, total_count

print("ok=%d" % int(ok_count))
print("total=%d" % int(total_count))
PY

validator_assert_contains "$tmpdir/out" 'ok=3'
validator_assert_contains "$tmpdir/out" 'total=5'
