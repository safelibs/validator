#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpath-string
# @title: lxml XPath string
# @description: Evaluates an XPath string concatenation through lxml and verifies the combined text value.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xpath-string"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><item>alpha</item><item>beta</item></root>')
print(root.xpath('concat(/root/item[1], "-", /root/item[2])'))
PY
validator_assert_contains "$tmpdir/out" 'alpha-beta'
