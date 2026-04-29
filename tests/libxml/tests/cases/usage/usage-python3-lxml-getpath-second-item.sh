#!/usr/bin/env bash
# @testcase: usage-python3-lxml-getpath-second-item
# @title: lxml getpath second item
# @description: Locates the second item through python3-lxml and verifies that ElementTree.getpath reports the expected absolute path.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-getpath-second-item"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/doc.xml"
cat >"$xml" <<'XML'
<root xmlns:ns="urn:test">
  <item id="a">alpha</item>
  <item id="b">beta</item>
  <ns:note>namespaced</ns:note>
</root>
XML

XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
node = tree.xpath('/root/item[@id="b"]')[0]
print(tree.getpath(node))
PYCASE
validator_assert_contains "$tmpdir/out" '/root/item[2]'
