#!/usr/bin/env bash
# @testcase: usage-python3-lxml-htmlparser-recover
# @title: lxml HTMLParser recover
# @description: Parses malformed HTML with lxml.etree.HTMLParser in recovery mode and verifies the recovered tree contains the expected tag set with exact element counts.
# @timeout: 180
# @tags: usage, xml, html, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from io import BytesIO
from lxml import etree

broken = b"<html><body><p>first<p>second<p>third<div>tail</body></html>"
parser = etree.HTMLParser(recover=True, no_network=True)
tree = etree.parse(BytesIO(broken), parser)
root = tree.getroot()

assert root.tag == "html", root.tag
paragraphs = root.findall(".//p")
assert len(paragraphs) == 3, len(paragraphs)
texts = [p.text for p in paragraphs]
assert texts == ["first", "second", "third"], texts

div_text = root.findtext(".//div")
assert div_text == "tail", div_text

print("root=" + root.tag)
print("p-count=" + str(len(paragraphs)))
print("texts=" + ",".join(texts))
print("div-text=" + div_text)
PY

validator_assert_contains "$tmpdir/out" 'root=html'
validator_assert_contains "$tmpdir/out" 'p-count=3'
validator_assert_contains "$tmpdir/out" 'texts=first,second,third'
validator_assert_contains "$tmpdir/out" 'div-text=tail'
