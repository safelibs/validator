#!/usr/bin/env bash
# @testcase: usage-python3-lxml-nsmap-lookup
# @title: lxml namespace map lookup
# @description: Runs a namespace-aware lookup through python3-lxml and verifies the selected namespaced text node.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-nsmap-lookup"
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
value = tree.xpath('string(//ns:note)', namespaces={'ns': 'urn:test'})
print(value)
PYCASE
validator_assert_contains "$tmpdir/out" 'namespaced'
