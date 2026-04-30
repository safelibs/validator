#!/usr/bin/env bash
# @testcase: usage-python3-lxml-schematron-validate
# @title: lxml Schematron validation
# @description: Validates an XML document against an ISO Schematron schema with python3-lxml and verifies a violating document is rejected with an exact failure report message.
# @timeout: 180
# @tags: usage, xml, python, validation
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree, isoschematron

schema_doc = etree.XML(b"""<schema xmlns="http://purl.oclc.org/dsdl/schematron">
  <pattern id="weights">
    <rule context="item">
      <assert test="@weight">item is missing weight</assert>
    </rule>
  </pattern>
</schema>""")
schematron = isoschematron.Schematron(schema_doc, store_report=True)

ok_doc = etree.XML(b'<root><item weight="1"/><item weight="2"/></root>')
bad_doc = etree.XML(b'<root><item weight="1"/><item/></root>')

assert schematron.validate(ok_doc) is True, "expected ok_doc to validate"
assert schematron.validate(bad_doc) is False, "expected bad_doc to fail"

report = etree.tostring(schematron.validation_report, encoding="unicode")
assert "item is missing weight" in report, report
print("ok=True")
print("bad=False")
print("report-has-message=True")
PY

validator_assert_contains "$tmpdir/out" 'ok=True'
validator_assert_contains "$tmpdir/out" 'bad=False'
validator_assert_contains "$tmpdir/out" 'report-has-message=True'
