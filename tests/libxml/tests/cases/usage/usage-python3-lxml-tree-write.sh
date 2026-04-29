#!/usr/bin/env bash
# @testcase: usage-python3-lxml-tree-write
# @title: lxml tree write
# @description: Writes an XML tree to disk through lxml and verifies the resulting file contains the expected declaration and node text.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-tree-write"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$tmpdir/out.xml"
from lxml import etree
import sys
tree = etree.ElementTree(etree.XML(b'<root><item>file</item></root>'))
tree.write(sys.argv[1], encoding="utf-8", xml_declaration=True)
print("written")
PY
validator_assert_contains "$tmpdir/out.xml" '<?xml'
validator_assert_contains "$tmpdir/out.xml" '<item>file</item>'
