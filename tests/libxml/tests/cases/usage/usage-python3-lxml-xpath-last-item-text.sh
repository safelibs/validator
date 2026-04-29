#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpath-last-item-text
# @title: lxml XPath last item text
# @description: Selects the last item element with python3-lxml's last() XPath function and verifies the trailing item text.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xpath-last-item-text"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/doc.xml"
cat >"$xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root xmlns:m="urn:meta">
  <item id="a" weight="2">alpha</item>
  <item id="b" weight="3">beta</item>
  <item id="c" weight="5">gamma</item>
  <m:tag>meta-tag</m:tag>
</root>
XML

XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
print(tree.xpath('string(/root/item[last()])'))
PYCASE
validator_assert_contains "$tmpdir/out" 'gamma'
