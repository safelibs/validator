#!/usr/bin/env bash
# @testcase: usage-python3-lxml-deepcopy-text
# @title: lxml deepcopy text
# @description: Deep-copies an XML tree with python3-lxml and verifies that mutating the clone leaves the original element text intact.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-deepcopy-text"
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
import copy
from lxml import etree
root = etree.XML(b'<root><item>alpha</item></root>')
clone = copy.deepcopy(root)
clone.find('item').text = 'beta'
print(root.find('item').text, clone.find('item').text)
PYCASE
validator_assert_contains "$tmpdir/out" 'alpha beta'
