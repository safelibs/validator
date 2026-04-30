#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-tr-identity-transform
# @title: xmlstarlet tr XSLT identity transform
# @description: Runs xmlstarlet tr with an XSLT identity transform that copies every node and attribute from the input document, and verifies that all source elements, attributes, and text content are preserved in the transformed output.
# @timeout: 180
# @tags: usage, xml, cli, xslt
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
  <item id="a" weight="2">alpha</item>
  <item id="b" weight="3">beta</item>
  <item id="c" weight="5">gamma</item>
</root>
XML

cat >"$tmpdir/identity.xsl" <<'XSL'
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml" indent="no"/>
  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
XSL

xmlstarlet tr "$tmpdir/identity.xsl" "$tmpdir/in.xml" >"$tmpdir/out.xml"

# Every source element must appear in the output.
validator_assert_contains "$tmpdir/out.xml" '<root>'
validator_assert_contains "$tmpdir/out.xml" '<item id="a" weight="2">alpha</item>'
validator_assert_contains "$tmpdir/out.xml" '<item id="b" weight="3">beta</item>'
validator_assert_contains "$tmpdir/out.xml" '<item id="c" weight="5">gamma</item>'

# And the post-transform structure exposes exactly the same item count.
count=$(xmlstarlet sel -t -v 'count(/root/item)' "$tmpdir/out.xml")
[[ "$count" == "3" ]] || {
  printf 'expected 3 items after identity transform, got %s\n' "$count" >&2
  cat "$tmpdir/out.xml" >&2
  exit 1
}

# Sum of weights must round-trip through the identity transform.
sum=$(xmlstarlet sel -t -v 'sum(/root/item/@weight)' "$tmpdir/out.xml")
[[ "$sum" == "10" ]] || {
  printf 'expected weight sum 10, got %s\n' "$sum" >&2
  exit 1
}
