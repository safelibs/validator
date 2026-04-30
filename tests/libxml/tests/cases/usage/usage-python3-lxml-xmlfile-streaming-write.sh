#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xmlfile-streaming-write
# @title: lxml xmlfile streaming write
# @description: Streams XML to disk with the etree.xmlfile incremental writer using element context managers, then re-parses the written file and verifies the root tag, total child count, and a specific child attribute through python3-lxml.
# @timeout: 180
# @tags: usage, xml, python, streaming
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xmlfile-streaming-write"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out_xml="$tmpdir/stream.xml"

python3 - "$out_xml" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

target = sys.argv[1]
with etree.xmlfile(target, encoding="utf-8") as xf:
    xf.write_declaration()
    with xf.element("root"):
        for i in range(5):
            with xf.element("item", id=str(i)):
                xf.write("v%d" % i)

# Reparse and verify.
parsed = etree.parse(target).getroot()
assert parsed.tag == "root", parsed.tag
items = parsed.findall("item")
assert len(items) == 5, len(items)
assert items[2].get("id") == "2", items[2].get("id")
assert items[2].text == "v2", items[2].text

print("root=" + parsed.tag)
print("items=" + str(len(items)))
print("item2-id=" + items[2].get("id"))
print("item2-text=" + items[2].text)
PY

validator_require_file "$out_xml"
validator_assert_contains "$out_xml" '<root>'
validator_assert_contains "$out_xml" 'id="3"'
validator_assert_contains "$tmpdir/out" 'root=root'
validator_assert_contains "$tmpdir/out" 'items=5'
validator_assert_contains "$tmpdir/out" 'item2-id=2'
validator_assert_contains "$tmpdir/out" 'item2-text=v2'
