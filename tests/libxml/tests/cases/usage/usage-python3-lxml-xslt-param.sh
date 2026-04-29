#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xslt-param
# @title: lxml XSLT parameter
# @description: Applies an XSLT transform with a string parameter through python3-lxml.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xslt-param"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
xml = etree.XML(b'<root><item>world</item></root>')
style = etree.XML(b'''<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:param name="prefix"/>
  <xsl:template match="/root"><out><xsl:value-of select="$prefix"/><xsl:value-of select="item"/></out></xsl:template>
</xsl:stylesheet>''')
transform = etree.XSLT(style)
result = transform(xml, prefix=etree.XSLT.strparam("hello "))
print(str(result))
PY
validator_assert_contains "$tmpdir/out" 'hello world'
