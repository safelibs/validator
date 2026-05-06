#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r9-xpath-position
# @title: lxml XPath position predicate
# @description: Parses an items list and uses an XPath position() predicate to select the second item, asserting the text matches.
# @timeout: 60
# @tags: usage, python3-lxml, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from lxml import etree
xml = b"""<root>
  <item>alpha</item>
  <item>beta</item>
  <item>gamma</item>
</root>"""
root = etree.fromstring(xml)
second = root.xpath('item[position()=2]')
assert len(second) == 1, len(second)
assert second[0].text == 'beta', second[0].text

last = root.xpath('item[last()]')
assert last[0].text == 'gamma', last[0].text
PY
