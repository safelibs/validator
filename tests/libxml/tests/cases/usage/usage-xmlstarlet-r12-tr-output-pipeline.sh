#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r12-tr-output-pipeline
# @title: xmlstarlet tr applies an XSLT 1.0 stylesheet from stdin and emits the rendered output
# @description: Pipes an XML document through xmlstarlet tr with a stylesheet that wraps each item value in a <line> element, and asserts the output contains exactly three rendered lines with the original item values preserved.
# @timeout: 60
# @tags: usage, xmlstarlet, xslt
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/sheet.xsl" <<'XSL'
<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="xml" indent="no"/>
  <xsl:template match="/items">
    <out>
      <xsl:for-each select="i">
        <line><xsl:value-of select="."/></line>
      </xsl:for-each>
    </out>
  </xsl:template>
</xsl:stylesheet>
XSL

cat >"$tmpdir/in.xml" <<'XML'
<items>
  <i>alpha</i>
  <i>beta</i>
  <i>gamma</i>
</items>
XML

xmlstarlet tr "$tmpdir/sheet.xsl" "$tmpdir/in.xml" >"$tmpdir/out.xml"

count=$(xmlstarlet sel -t -v 'count(/out/line)' "$tmpdir/out.xml")
[[ "$count" == "3" ]] || {
    printf 'expected 3 line elements, got %s\n' "$count" >&2
    cat "$tmpdir/out.xml" >&2
    exit 1
}
validator_assert_contains "$tmpdir/out.xml" '<line>alpha</line>'
validator_assert_contains "$tmpdir/out.xml" '<line>beta</line>'
validator_assert_contains "$tmpdir/out.xml" '<line>gamma</line>'
