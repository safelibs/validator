#!/usr/bin/env bash
# @testcase: usage-python3-lxml-relaxng
# @title: lxml RelaxNG validation
# @description: Validates an XML document with a RelaxNG schema through python3-lxml.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-relaxng"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
schema = etree.RelaxNG(etree.XML(b'<element name="root" xmlns="http://relaxng.org/ns/structure/1.0"><text/></element>'))
doc = etree.XML(b'<root>ok</root>')
print(schema.validate(doc))
PY
validator_assert_contains "$tmpdir/out" 'True'
