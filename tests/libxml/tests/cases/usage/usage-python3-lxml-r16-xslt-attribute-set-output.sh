#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r16-xslt-attribute-set-output
# @title: lxml XSLT inline stylesheet rewrites element to <out value="N"> for each input node
# @description: Compiles a small XSLT 1.0 stylesheet that maps <item><val>N</val></item> to <out value="N"/>, applies it to a three-item document, and asserts the serialized result contains exactly three <out> elements with attribute values 1, 2, 3 in order.
# @timeout: 60
# @tags: usage, xml, python, xslt
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

src = etree.fromstring(
    b'<root>'
    b'<item><val>1</val></item>'
    b'<item><val>2</val></item>'
    b'<item><val>3</val></item>'
    b'</root>'
)
xslt = etree.XSLT(etree.fromstring(b"""<?xml version='1.0'?>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
  <xsl:output method='xml' omit-xml-declaration='yes'/>
  <xsl:template match='/root'>
    <results><xsl:apply-templates select='item'/></results>
  </xsl:template>
  <xsl:template match='item'>
    <out value='{val}'/>
  </xsl:template>
</xsl:stylesheet>"""))
result = xslt(src)
print('result=' + str(result).strip())
PY

validator_assert_contains "$tmpdir/out" '<out value="1"/>'
validator_assert_contains "$tmpdir/out" '<out value="2"/>'
validator_assert_contains "$tmpdir/out" '<out value="3"/>'
count=$(grep -o '<out value=' "$tmpdir/out" | wc -l)
[[ "$count" == "3" ]] || {
    printf 'expected 3 <out> elements, got %s\n' "$count" >&2
    exit 1
}
