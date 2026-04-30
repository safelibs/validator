#!/usr/bin/env bash
# @testcase: usage-python3-lxml-treebuilder-build
# @title: lxml TreeBuilder build
# @description: Builds a document incrementally with lxml TreeBuilder events and verifies the serialized output and exact attribute set of the constructed root element.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

builder = etree.TreeBuilder()
builder.start("catalog", {"version": "1", "lang": "en"})
builder.start("entry", {"id": "1"})
builder.data("alpha")
builder.end("entry")
builder.start("entry", {"id": "2"})
builder.data("beta")
builder.end("entry")
builder.end("catalog")
root = builder.close()

attrib = sorted(root.attrib.items())
assert attrib == [("lang", "en"), ("version", "1")], attrib

serialized = etree.tostring(root, encoding="unicode")
expected = '<catalog version="1" lang="en"><entry id="1">alpha</entry><entry id="2">beta</entry></catalog>'
assert serialized == expected, serialized

print("attribs=" + ",".join(f"{k}={v}" for k, v in attrib))
print("serialized=" + serialized)
print("entries=" + str(len(root.findall("entry"))))
PY

validator_assert_contains "$tmpdir/out" 'attribs=lang=en,version=1'
validator_assert_contains "$tmpdir/out" '<catalog version="1" lang="en">'
validator_assert_contains "$tmpdir/out" 'entries=2'
