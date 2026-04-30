#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xmlschema-complex-xsd
# @title: lxml XMLSchema complex XSD validate
# @description: Loads a multi-element XSD with type restrictions and required attributes, validates a conforming document successfully, then validates a non-conforming document (missing required attribute) and verifies the schema error log surfaces the specific validation failure.
# @timeout: 180
# @tags: usage, xml, python, xsd
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xmlschema-complex-xsd"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/schema.xsd" <<'XSD'
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="catalog">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="book" maxOccurs="unbounded">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="title" type="xs:string"/>
              <xs:element name="pages" type="xs:positiveInteger"/>
            </xs:sequence>
            <xs:attribute name="id" type="xs:string" use="required"/>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
XSD

cat >"$tmpdir/good.xml" <<'XML'
<catalog>
  <book id="b1"><title>Alpha</title><pages>120</pages></book>
  <book id="b2"><title>Beta</title><pages>240</pages></book>
</catalog>
XML

cat >"$tmpdir/bad.xml" <<'XML'
<catalog>
  <book><title>Gamma</title><pages>50</pages></book>
</catalog>
XML

python3 - "$tmpdir/schema.xsd" "$tmpdir/good.xml" "$tmpdir/bad.xml" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

xsd_path, good_path, bad_path = sys.argv[1], sys.argv[2], sys.argv[3]
schema = etree.XMLSchema(etree.parse(xsd_path))

good_doc = etree.parse(good_path)
bad_doc = etree.parse(bad_path)

good_ok = schema.validate(good_doc)
bad_ok = schema.validate(bad_doc)

assert good_ok is True, good_ok
assert bad_ok is False, bad_ok

errors = list(schema.error_log)
assert errors, "expected at least one validation error for bad doc"
joined = " | ".join(e.message for e in errors)

print("good=" + str(good_ok))
print("bad=" + str(bad_ok))
print("error-count=" + str(len(errors)))
print("first-error=" + errors[0].message)
print("joined=" + joined)
PY

validator_assert_contains "$tmpdir/out" 'good=True'
validator_assert_contains "$tmpdir/out" 'bad=False'
validator_assert_contains "$tmpdir/out" 'first-error='
grep -Eq "id|attribute" "$tmpdir/out" || {
  printf 'expected validation error to mention missing required attribute id\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
}
