#!/usr/bin/env bash
# @testcase: usage-python3-lxml-qname-tag-text
# @title: lxml QName tag access via element creation
# @description: Constructs an element using lxml.etree.QName with both a namespace URI and a localname, verifies the element tag is rendered in Clark notation, then reads the QName.text representation and the parsed namespace and localname back out, exercising lxml QName tag-access semantics.
# @timeout: 180
# @tags: usage, xml, python, qname
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

qname = etree.QName("urn:validator:test", "item")
assert qname.localname == "item", qname.localname
assert qname.namespace == "urn:validator:test", qname.namespace
assert qname.text == "{urn:validator:test}item", qname.text
assert str(qname) == "{urn:validator:test}item", str(qname)

# Use QName as a tag when creating an element.
elem = etree.Element(qname, attrib={"id": "x"})
assert elem.tag == "{urn:validator:test}item", elem.tag

# Round-trip back through QName from the element tag.
parsed = etree.QName(elem.tag)
assert parsed.namespace == "urn:validator:test", parsed.namespace
assert parsed.localname == "item", parsed.localname

print("text=" + qname.text)
print("namespace=" + qname.namespace)
print("localname=" + qname.localname)
print("elem-tag=" + elem.tag)
print("parsed-localname=" + parsed.localname)
PY

validator_assert_contains "$tmpdir/out" 'text={urn:validator:test}item'
validator_assert_contains "$tmpdir/out" 'namespace=urn:validator:test'
validator_assert_contains "$tmpdir/out" 'localname=item'
validator_assert_contains "$tmpdir/out" 'elem-tag={urn:validator:test}item'
validator_assert_contains "$tmpdir/out" 'parsed-localname=item'
