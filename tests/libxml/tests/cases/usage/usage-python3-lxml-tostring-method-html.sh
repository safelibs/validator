#!/usr/bin/env bash
# @testcase: usage-python3-lxml-tostring-method-html
# @title: lxml tostring method html
# @description: Parses an XML tree containing self-closing void elements, serializes it via etree.tostring with method='html', and verifies that void tags such as <br> and <img> are emitted in HTML form rather than as XML self-closing tags.
# @timeout: 180
# @tags: usage, xml, python, html
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-tostring-method-html"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.XML(b'<html><body><p>hello<br/>world</p><img src="x.png"/></body></html>')
html_bytes = etree.tostring(root, method="html")
xml_bytes = etree.tostring(root, method="xml")

html_text = html_bytes.decode()
xml_text = xml_bytes.decode()

assert "<br>" in html_text, html_text
assert '<img src="x.png">' in html_text, html_text
assert "<br/>" not in html_text, html_text
assert "<br/>" in xml_text, xml_text

print("html=" + html_text)
print("xml=" + xml_text)
PY

validator_assert_contains "$tmpdir/out" '<br>'
validator_assert_contains "$tmpdir/out" '<img src="x.png">'
validator_assert_contains "$tmpdir/out" 'xml=<html>'
