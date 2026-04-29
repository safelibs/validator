#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

case "$case_id" in
  usage-python3-lxml-remove-comments-parser-batch11)
    python3 - "$tmpdir/items.xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
parser = etree.XMLParser(remove_comments=True)
root = etree.parse(sys.argv[1], parser).getroot()
print(len(root.xpath('//comment()')))
PYCASE
    validator_assert_contains "$tmpdir/out" '0'
    ;;
  usage-python3-lxml-processing-instruction-batch11)
    python3 - "$tmpdir/items.xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
root = etree.parse(sys.argv[1]).getroot()
pi = root.xpath('//processing-instruction()')[0]
print(pi.target + ':' + pi.text)
PYCASE
    validator_assert_contains "$tmpdir/out" 'note:ok'
    ;;
  usage-python3-lxml-xpath-variable-batch11)
    python3 - "$tmpdir/items.xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
root = etree.parse(sys.argv[1]).getroot()
print(root.xpath('string(//item[@id=$wanted])', wanted='b'))
PYCASE
    validator_assert_contains "$tmpdir/out" 'Beta'
    ;;
  usage-python3-lxml-xslt-text-output-batch11)
    python3 - "$tmpdir/items.xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
style = etree.XML(b"""<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"><xsl:output method="text"/><xsl:template match="/"><xsl:value-of select="sum(//item/@weight)"/></xsl:template></xsl:stylesheet>""")
result = etree.XSLT(style)(etree.parse(sys.argv[1]))
print(str(result))
PYCASE
    validator_assert_contains "$tmpdir/out" '5'
    ;;
  usage-python3-lxml-objectify-attribute-batch11)
    python3 >"$tmpdir/out" <<'PYCASE'
from lxml import objectify
root = objectify.fromstring(b'<root><item code="x">7</item></root>')
print(root.item.get('code'))
PYCASE
    validator_assert_contains "$tmpdir/out" 'x'
    ;;
  usage-xmlstarlet-elements-list-batch11)
    xmlstarlet el "$tmpdir/items.xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'root/item'
    ;;
  usage-xmlstarlet-select-if-batch11)
    xmlstarlet sel -t -m '//item[@weight > 2]' -v @id "$tmpdir/items.xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'b'
    ;;
  usage-xmlstarlet-edit-subnode-batch11)
    xmlstarlet ed -s /root -t elem -n extra -v value "$tmpdir/items.xml" >"$tmpdir/out.xml"
    validator_assert_contains "$tmpdir/out.xml" '<extra>value</extra>'
    ;;
  usage-xmlstarlet-format-indent-batch11)
    xmlstarlet fo -s 2 "$tmpdir/items.xml" >"$tmpdir/out.xml"
    validator_assert_contains "$tmpdir/out.xml" '  <item'
    ;;
  usage-xmlstarlet-c14n-with-comments-batch11)
    xmlstarlet c14n --with-comments "$tmpdir/items.xml" >"$tmpdir/out.xml"
    validator_assert_contains "$tmpdir/out.xml" '<!--drop-->'
    ;;
  *)
    printf 'unknown libxml eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
