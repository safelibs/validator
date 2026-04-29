#!/usr/bin/env bash
# @testcase: usage-python3-lxml-attrib-items-list
# @title: lxml attrib items list
# @description: Iterates the attribute mapping with python3-lxml's attrib.items and verifies the emitted attribute name-value pairs.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-attrib-items-list"
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

python3 >"$tmpdir/out" <<'PYCASE'
from lxml import etree
node = etree.XML(b'<item id="a" weight="3"/>')
pairs = sorted(node.attrib.items())
print(','.join('{}={}'.format(k, v) for k, v in pairs))
PYCASE
validator_assert_contains "$tmpdir/out" 'id=a,weight=3'
