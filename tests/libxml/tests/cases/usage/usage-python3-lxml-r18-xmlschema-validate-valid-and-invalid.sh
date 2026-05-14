#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r18-xmlschema-validate-valid-and-invalid
# @title: lxml etree.XMLSchema accepts conformant XML and rejects non-conformant XML
# @description: Builds an etree.XMLSchema from an inline XSD and asserts a conformant document validates True while a non-conformant document (extra unexpected element) validates False, exercising the libxml2 XSD path through lxml.
# @timeout: 60
# @tags: usage, xml, python, xsd, r18
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xsd = etree.XMLSchema(etree.fromstring(b'''<?xml version="1.0"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="root">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="item" type="xs:string"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>'''))

good = etree.fromstring(b'<root><item>v</item></root>')
bad = etree.fromstring(b'<root><item>v</item><extra/></root>')

print('good=' + str(xsd.validate(good)))
print('bad=' + str(xsd.validate(bad)))
PY

validator_assert_contains "$tmpdir/out" 'good=True'
validator_assert_contains "$tmpdir/out" 'bad=False'
