#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-validate-xsd-schema-r8
# @title: xmlstarlet val W3C XML Schema
# @description: Validates a conforming document against a W3C XML Schema (XSD) via xmlstarlet val -s and rejects a non-conforming document, verifying the per-document validity verdict text and that the bad case exits non-zero.
# @timeout: 180
# @tags: usage, xml, cli, validation, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/schema.xsd" <<'XSD'
<?xml version="1.0" encoding="UTF-8"?>
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
           elementFormDefault="qualified">
  <xs:element name="catalog">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="item" maxOccurs="unbounded">
          <xs:complexType>
            <xs:simpleContent>
              <xs:extension base="xs:string">
                <xs:attribute name="id" type="xs:string" use="required"/>
              </xs:extension>
            </xs:simpleContent>
          </xs:complexType>
        </xs:element>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
XSD

cat >"$tmpdir/good.xml" <<'XML'
<catalog>
  <item id="1">alpha</item>
  <item id="2">beta</item>
</catalog>
XML

cat >"$tmpdir/bad.xml" <<'XML'
<catalog>
  <item id="1">alpha</item>
  <item>missing-id</item>
</catalog>
XML

xmlstarlet val -s "$tmpdir/schema.xsd" "$tmpdir/good.xml" >"$tmpdir/good.out"
validator_assert_contains "$tmpdir/good.out" 'good.xml - valid'

set +e
xmlstarlet val -e -s "$tmpdir/schema.xsd" "$tmpdir/bad.xml" >"$tmpdir/bad.out" 2>&1
bad_status=$?
set -e

[[ "$bad_status" -ne 0 ]] || {
  printf 'expected non-zero exit on invalid doc, got %s\n' "$bad_status" >&2
  cat "$tmpdir/bad.out" >&2
  exit 1
}
validator_assert_contains "$tmpdir/bad.out" 'bad.xml'
