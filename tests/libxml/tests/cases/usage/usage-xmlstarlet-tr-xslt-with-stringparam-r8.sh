#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-tr-xslt-with-stringparam-r8
# @title: xmlstarlet tr applies XSLT with -s string parameter
# @description: Runs xmlstarlet tr to apply an XSLT stylesheet that consumes a top-level <xsl:param> populated via -s name=value on the command line, verifying the parameter value is interpolated into the output and the result also reflects the input data.
# @timeout: 180
# @tags: usage, xml, cli, xslt, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<doc>
  <name>world</name>
</doc>
XML

cat >"$tmpdir/style.xsl" <<'XSL'
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="text" encoding="UTF-8"/>
  <xsl:param name="greeting" select="'Hi'"/>
  <xsl:template match="/doc">
    <xsl:value-of select="$greeting"/>
    <xsl:text>, </xsl:text>
    <xsl:value-of select="name"/>
    <xsl:text>!</xsl:text>
  </xsl:template>
</xsl:stylesheet>
XSL

xmlstarlet tr "$tmpdir/style.xsl" -s greeting=Hello "$tmpdir/in.xml" >"$tmpdir/out"

got=$(cat "$tmpdir/out")
[[ "$got" == "Hello, world!" ]] || {
  printf 'unexpected XSLT output: %q\n' "$got" >&2
  exit 1
}
