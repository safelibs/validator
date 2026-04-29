#!/usr/bin/env bash
# @testcase: usage-python3-lxml-dtd-validate
# @title: lxml DTD validation
# @description: Validates an XML document against an inline DTD with python3-lxml.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-dtd-validate"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from io import StringIO
from lxml import etree
dtd = etree.DTD(StringIO('<!ELEMENT root (item)>\n<!ELEMENT item (#PCDATA)>'))
doc = etree.XML('<root><item>ok</item></root>')
print(dtd.validate(doc))
PY
validator_assert_contains "$tmpdir/out" 'True'
