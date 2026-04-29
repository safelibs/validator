#!/usr/bin/env bash
# @testcase: usage-python3-lxml-html-parse
# @title: lxml HTML parse
# @description: Parses simple HTML through lxml.html and verifies text extraction from the document tree.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-html-parse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree, html
root = html.fromstring(b'<html><body><p>hello</p></body></html>')
print(root.xpath('string(//p)'))
PY
validator_assert_contains "$tmpdir/out" 'hello'
