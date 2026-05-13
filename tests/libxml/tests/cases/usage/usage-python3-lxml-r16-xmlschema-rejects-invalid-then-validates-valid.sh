#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r16-xmlschema-rejects-invalid-then-validates-valid
# @title: lxml etree.XMLSchema accepts a valid instance and rejects one missing a required element
# @description: Compiles an XSD that requires an <id> child of <person>, asserts validate(valid_doc) returns True and validate(invalid_doc) returns False with error_log non-empty, exercising libxml2's XML Schema validator path through lxml.
# @timeout: 60
# @tags: usage, xml, python, schema, xsd
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xsd_doc = etree.fromstring(b"""<?xml version='1.0'?>
<xs:schema xmlns:xs='http://www.w3.org/2001/XMLSchema'>
  <xs:element name='person'>
    <xs:complexType>
      <xs:sequence>
        <xs:element name='id' type='xs:integer'/>
        <xs:element name='name' type='xs:string'/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>""")
schema = etree.XMLSchema(xsd_doc)

valid = etree.fromstring(b'<person><id>7</id><name>Ada</name></person>')
invalid = etree.fromstring(b'<person><name>Ada</name></person>')

print('valid=' + str(schema.validate(valid)))
print('invalid=' + str(schema.validate(invalid)))
print('err_count=' + str(len(schema.error_log)))
PY

validator_assert_contains "$tmpdir/out" 'valid=True'
validator_assert_contains "$tmpdir/out" 'invalid=False'
# error_log should have at least one entry after the rejection.
grep -Eq '^err_count=[1-9][0-9]*$' "$tmpdir/out" || {
    printf 'expected non-zero err_count\n' >&2
    cat "$tmpdir/out" >&2
    exit 1
}
