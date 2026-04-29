#!/usr/bin/env bash
# @testcase: usage-python3-lxml-cdata-node
# @title: lxml CDATA node
# @description: Serializes a CDATA section with python3-lxml and verifies the CDATA wrapper is preserved.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-cdata-node"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.Element("root")
item = etree.SubElement(root, "item")
item.text = etree.CDATA("a < b")
print(etree.tostring(root).decode())
PY
validator_assert_contains "$tmpdir/out" '<![CDATA[a < b]]>'
