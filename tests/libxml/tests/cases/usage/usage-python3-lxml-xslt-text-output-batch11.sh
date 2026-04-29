#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xslt-text-output-batch11
# @title: lxml XSLT text output
# @description: Runs an lxml XSLT transform that emits text output.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xslt-text-output-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

python3 - "$tmpdir/items.xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
style = etree.XML(b"""<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"><xsl:output method="text"/><xsl:template match="/"><xsl:value-of select="sum(//item/@weight)"/></xsl:template></xsl:stylesheet>""")
result = etree.XSLT(style)(etree.parse(sys.argv[1]))
print(str(result))
PYCASE
validator_assert_contains "$tmpdir/out" '5'
