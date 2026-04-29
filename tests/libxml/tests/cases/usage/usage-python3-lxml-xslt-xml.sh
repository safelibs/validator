#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xslt-xml
# @title: python3-lxml xslt xml
# @description: Runs python3-lxml xslt xml behavior through libxml2.
# @timeout: 180
# @tags: usage, xml
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    validator_make_fixture "$tmpdir/in.xml" "<root><item name=\"alpha\">1</item><item name=\"beta\">2</item></root>"
python3 - <<'PY' "$tmpdir/in.xml"
from lxml import etree
import sys
xml=etree.parse(sys.argv[1]); style=etree.XML(b'<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"><xsl:template match="/"><out><xsl:value-of select="/root/item[1]"/></out></xsl:template></xsl:stylesheet>'); print(str(etree.XSLT(style)(xml)))
PY
