#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r21-xslt-string-param-passing
# @title: lxml XSLT accepts a string parameter via XSLT.strparam and emits it in the result
# @description: Compiles an XSLT stylesheet that copies a top-level <param> value into the output, invokes the transform with XSLT.strparam('value'), and asserts the serialized output contains exactly that string — pinning lxml/libxslt parameter passing on Ubuntu 24.04.
# @timeout: 60
# @tags: usage, xml, python, xslt, param, r21
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
from lxml import etree

xslt = etree.fromstring(b"""<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:param name="who"/>
  <xsl:template match="/">
    <out><xsl:value-of select="$who"/></out>
  </xsl:template>
</xsl:stylesheet>""")
transform = etree.XSLT(xslt)
src = etree.fromstring(b'<r/>')
result = transform(src, who=etree.XSLT.strparam('hello-r21'))
serialized = bytes(result)
assert b'<out>hello-r21</out>' in serialized, serialized
PY
