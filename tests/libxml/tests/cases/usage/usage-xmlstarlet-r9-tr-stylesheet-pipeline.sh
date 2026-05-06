#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r9-tr-stylesheet-pipeline
# @title: xmlstarlet tr applies XSLT stylesheet
# @description: Transforms an items list to plain text via xmlstarlet tr with a small XSLT stylesheet and verifies the concatenated values appear in order.
# @timeout: 60
# @tags: usage, xmlstarlet, xslt
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item>alpha</item>
  <item>beta</item>
  <item>gamma</item>
</root>
XML

cat >"$tmpdir/sheet.xsl" <<'XSL'
<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:template match="/root">
    <xsl:for-each select="item">
      <xsl:value-of select="."/>
      <xsl:text>;</xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
XSL

xmlstarlet tr "$tmpdir/sheet.xsl" "$tmpdir/in.xml" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha;beta;gamma;'
