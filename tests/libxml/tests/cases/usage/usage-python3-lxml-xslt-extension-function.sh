#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xslt-extension-function
# @title: lxml XSLT extension function
# @description: Registers a Python XSLT 1.0 extension function via lxml and verifies the transform output applies the custom function.
# @timeout: 180
# @tags: usage, xml, python, xslt
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item>alpha</item>
  <item>beta</item>
</root>
XML

cat >"$tmpdir/style.xsl" <<'XSL'
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:ext="urn:validator-ext"
                extension-element-prefixes="ext"
                version="1.0">
  <xsl:output method="text"/>
  <xsl:template match="/">
    <xsl:for-each select="/root/item">
      <xsl:value-of select="ext:upper(string(.))"/>
      <xsl:text>|</xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
XSL

python3 - "$tmpdir/in.xml" "$tmpdir/style.xsl" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

ns = etree.FunctionNamespace("urn:validator-ext")
ns.prefix = "ext"

def upper(context, value):
    return value.upper()

ns["upper"] = upper

doc = etree.parse(sys.argv[1])
style = etree.parse(sys.argv[2])
result = etree.XSLT(style)(doc)
out = str(result).strip()
assert out == "ALPHA|BETA|", out
print(out)
PY

validator_assert_contains "$tmpdir/out" 'ALPHA|BETA|'
