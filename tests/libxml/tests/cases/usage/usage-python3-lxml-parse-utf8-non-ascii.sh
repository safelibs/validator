#!/usr/bin/env bash
# @testcase: usage-python3-lxml-parse-utf8-non-ascii
# @title: lxml parse UTF-8 non-ASCII payload
# @description: Parses an XML document containing non-ASCII UTF-8 text (Greek, Cyrillic, and CJK characters) and an XML declaration encoding=UTF-8 through lxml.etree.parse, then verifies that text content round-trips byte-for-byte and the XPath string() of each element returns the expected non-ASCII payload.
# @timeout: 180
# @tags: usage, xml, python, encoding
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/utf8.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <item lang="el">Καλημέρα</item>
  <item lang="ru">Привет</item>
  <item lang="ja">こんにちは</item>
</root>
XML

XML_PATH="$tmpdir/utf8.xml" python3 - >"$tmpdir/out" <<'PY'
import os
from lxml import etree

tree = etree.parse(os.environ["XML_PATH"])
root = tree.getroot()

assert root.tag == "root", root.tag
items = root.findall("item")
assert len(items) == 3, len(items)

texts = {item.get("lang"): item.text for item in items}
assert texts["el"] == "Καλημέρα", repr(texts["el"])
assert texts["ru"] == "Привет", repr(texts["ru"])
assert texts["ja"] == "こんにちは", repr(texts["ja"])

# XPath string() must return the same non-ASCII text.
xp_el = tree.xpath("string(/root/item[@lang='el'])")
xp_ru = tree.xpath("string(/root/item[@lang='ru'])")
xp_ja = tree.xpath("string(/root/item[@lang='ja'])")
assert xp_el == "Καλημέρα", repr(xp_el)
assert xp_ru == "Привет", repr(xp_ru)
assert xp_ja == "こんにちは", repr(xp_ja)

print("el=" + xp_el)
print("ru=" + xp_ru)
print("ja=" + xp_ja)
PY

validator_assert_contains "$tmpdir/out" 'el=Καλημέρα'
validator_assert_contains "$tmpdir/out" 'ru=Привет'
validator_assert_contains "$tmpdir/out" 'ja=こんにちは'
