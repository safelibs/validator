#!/usr/bin/env bash
# @testcase: usage-python3-lxml-pretty-print
# @title: lxml pretty print
# @description: Serializes parsed XML with lxml pretty-print formatting.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-pretty-print"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><item>1</item></root>')
print(etree.tostring(root, pretty_print=True).decode())
PY
validator_assert_contains "$tmpdir/out" '  <item>1</item>'
