#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r9-xslt-identity-transform
# @title: lxml XSLT identity transform
# @description: Compiles an identity XSLT 1.0 stylesheet and applies it to a tree, verifying the serialized result preserves the structure.
# @timeout: 60
# @tags: usage, python3-lxml, xslt
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from lxml import etree
src = etree.fromstring(b'<root><a x="1"/><b>txt</b></root>')
xslt_doc = etree.fromstring(b"""<?xml version='1.0'?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:template match='@*|node()'>
    <xsl:copy>
      <xsl:apply-templates select='@*|node()'/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>""")
xslt = etree.XSLT(xslt_doc)
result = xslt(src)
out = bytes(result)
assert b'<a x="1"' in out, out
assert b'<b>txt</b>' in out, out
PY
