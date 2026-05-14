#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r18-xslt-identity-transform-roundtrip
# @title: lxml etree.XSLT identity stylesheet preserves the root tag and child count
# @description: Compiles an XSLT identity stylesheet via lxml.etree.XSLT, applies it to a small input document, and asserts the transformed tree has the same root tag and child element count as the source — exercising the libxslt-backed transform path.
# @timeout: 60
# @tags: usage, xml, python, xslt, r18
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xslt_src = b'''<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>'''

doc = etree.fromstring(b'<root><a/><b/><c/></root>')
xslt = etree.XSLT(etree.fromstring(xslt_src))
out = xslt(doc)
out_root = out.getroot()
print('tag=' + out_root.tag)
print('children=' + str(len(out_root)))
PY

validator_assert_contains "$tmpdir/out" 'tag=root'
validator_assert_contains "$tmpdir/out" 'children=3'
