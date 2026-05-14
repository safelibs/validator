#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r17-tr-inline-xslt-identity
# @title: xmlstarlet tr applies an identity XSLT and preserves the input document structure
# @description: Runs xmlstarlet tr with a minimal identity XSLT stylesheet against a small XML input and asserts the transformed output contains the same root element and child <item> texts as the source, exercising libxslt through the xmlstarlet tr entry point.
# @timeout: 60
# @tags: usage, xmlstarlet, xslt, tr
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root>
  <item>alpha</item>
  <item>bravo</item>
</root>
XML

cat >"$tmpdir/id.xsl" <<'XSL'
<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
XSL

xmlstarlet tr "$tmpdir/id.xsl" "$tmpdir/in.xml" >"$tmpdir/out.xml"
validator_assert_contains "$tmpdir/out.xml" '<root>'
validator_assert_contains "$tmpdir/out.xml" 'alpha'
validator_assert_contains "$tmpdir/out.xml" 'bravo'
