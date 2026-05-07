#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r12-xslt-output-method-text
# @title: lxml XSLT with xsl:output method='text' emits the concatenated text without markup
# @description: Compiles an XSLT 1.0 stylesheet that declares xsl:output method='text', applies it to a tiny element tree, and asserts the resulting bytes contain only the concatenated value-of output with no XML angle brackets.
# @timeout: 60
# @tags: usage, xml, python, xslt
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/sheet.xsl" <<'XSL'
<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text"/>
  <xsl:template match="/items">
    <xsl:for-each select="i">
      <xsl:value-of select="."/>
      <xsl:text>|</xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
XSL

python3 - "$tmpdir/sheet.xsl" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

xslt = etree.XSLT(etree.parse(sys.argv[1]))
src = etree.fromstring(b'<items><i>alpha</i><i>beta</i><i>gamma</i></items>')
result = xslt(src)
text = bytes(result).decode('utf-8')
print('text=' + text)
print('has_lt=' + str('<' in text))
PY

validator_assert_contains "$tmpdir/out" 'text=alpha|beta|gamma|'
validator_assert_contains "$tmpdir/out" 'has_lt=False'
