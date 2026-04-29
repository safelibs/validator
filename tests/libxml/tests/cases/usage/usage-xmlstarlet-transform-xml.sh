#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-transform-xml
# @title: xmlstarlet transform XML
# @description: Runs xmlstarlet XSLT transformation and verifies the selected XML value is emitted.
# @timeout: 180
# @tags: usage, xml, cli
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item name="alpha">1</item>
  <item name="beta">2</item>
</root>
XML

cat >"$tmpdir/transform.xsl" <<'XSL'
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="text"/>
  <xsl:template match="/">
    <xsl:value-of select="/root/item[@name='beta']"/>
  </xsl:template>
</xsl:stylesheet>
XSL

xmlstarlet tr "$tmpdir/transform.xsl" "$tmpdir/in.xml" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" '2'
