#!/usr/bin/env bash
# @testcase: usage-python3-lxml-attribute-update
# @title: lxml attribute update
# @description: Updates an XML attribute through lxml and verifies the serialized output contains the new attribute value.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-attribute-update"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><item/></root>')
root.find("item").set("status", "ok")
print(etree.tostring(root).decode())
PY
validator_assert_contains "$tmpdir/out" 'status="ok"'
