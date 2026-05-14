#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r18-iterparse-tag-filter-counts
# @title: lxml iterparse with tag filter yields only elements matching the requested tag
# @description: Streams an XML payload through etree.iterparse with tag='item' and asserts the iterator yields exactly three end events corresponding to the three <item> elements in the input, ignoring all other tags.
# @timeout: 60
# @tags: usage, xml, python, iterparse, r18
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root>
  <item>a</item>
  <other>x</other>
  <item>b</item>
  <wrap><item>c</item></wrap>
</root>
XML

python3 - "$tmpdir/in.xml" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

count = 0
for event, elem in etree.iterparse(sys.argv[1], tag='item'):
    assert elem.tag == 'item', elem.tag
    count += 1
    elem.clear()
print('count=' + str(count))
PY

validator_assert_contains "$tmpdir/out" 'count=3'
