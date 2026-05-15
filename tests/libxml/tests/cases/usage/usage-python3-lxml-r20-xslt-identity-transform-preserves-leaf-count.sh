#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r20-xslt-identity-transform-preserves-leaf-count
# @title: lxml XSLT identity transform preserves the number of leaf elements
# @description: Compiles an identity-stylesheet XSLT via etree.XSLT, applies it to a tree containing three <item> children, serializes the result, and asserts re-parsing it yields exactly three <item> nodes — pinning the libxslt-driven identity transform's structural preservation through lxml.
# @timeout: 60
# @tags: usage, xml, python, xslt, identity, r20
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from lxml import etree

xslt_doc = etree.fromstring(b"""<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>""")
transform = etree.XSLT(xslt_doc)

src = etree.fromstring(b'<r><item>a</item><item>b</item><item>c</item></r>')
out = transform(src)
out_root = etree.fromstring(bytes(out))
assert len(out_root.findall('item')) == 3, etree.tostring(out_root)
PY
