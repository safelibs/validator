#!/usr/bin/env bash
# @testcase: usage-python3-lxml-bytesio-parse
# @title: lxml BytesIO parse
# @description: Parses XML from an in-memory byte stream through lxml and verifies the selected text node.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-bytesio-parse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from io import BytesIO
from lxml import etree
root = etree.parse(BytesIO(b'<root><item>ok</item></root>')).getroot()
print(root.xpath('string(item)'))
PY
validator_assert_contains "$tmpdir/out" 'ok'
