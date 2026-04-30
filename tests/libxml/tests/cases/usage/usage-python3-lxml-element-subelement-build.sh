#!/usr/bin/env bash
# @testcase: usage-python3-lxml-element-subelement-build
# @title: lxml etree.Element and SubElement programmatic build
# @description: Builds an XML tree programmatically with lxml.etree.Element and SubElement, sets attributes via the constructor and the .set API, and verifies the serialized form, child count, and attribute ordering as exposed by lxml.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.Element("catalog", version="1")
for idx, name in enumerate(("alpha", "beta", "gamma"), start=1):
    child = etree.SubElement(root, "entry", id=str(idx))
    child.set("name", name)
    child.text = name.upper()

assert len(root) == 3, len(root)
assert root.tag == "catalog", root.tag
assert root.get("version") == "1"

ids = [c.get("id") for c in root]
names = [c.get("name") for c in root]
assert ids == ["1", "2", "3"], ids
assert names == ["alpha", "beta", "gamma"], names

serialized = etree.tostring(root, encoding="unicode")
print("serialized=" + serialized)
print("children=" + str(len(root)))
print("ids=" + ",".join(ids))
print("names=" + ",".join(names))
PY

validator_assert_contains "$tmpdir/out" 'children=3'
validator_assert_contains "$tmpdir/out" 'ids=1,2,3'
validator_assert_contains "$tmpdir/out" 'names=alpha,beta,gamma'
validator_assert_contains "$tmpdir/out" '<catalog version="1">'
validator_assert_contains "$tmpdir/out" '<entry id="1" name="alpha">ALPHA</entry>'
