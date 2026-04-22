#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-lxml-namespace-xpath)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root xmlns:a="urn:a"><a:item>value</a:item></root>')
print(root.xpath('string(/root/a:item)', namespaces={'a': 'urn:a'}))
PY
    validator_assert_contains "$tmpdir/out" 'value'
    ;;
  usage-python3-lxml-pretty-print)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><item>1</item></root>')
print(etree.tostring(root, pretty_print=True).decode())
PY
    validator_assert_contains "$tmpdir/out" '  <item>1</item>'
    ;;
  usage-python3-lxml-dtd-validate)
    python3 - <<'PY' | tee "$tmpdir/out"
from io import StringIO
from lxml import etree
dtd = etree.DTD(StringIO('<!ELEMENT root (item)>\n<!ELEMENT item (#PCDATA)>'))
doc = etree.XML('<root><item>ok</item></root>')
print(dtd.validate(doc))
PY
    validator_assert_contains "$tmpdir/out" 'True'
    ;;
  usage-python3-lxml-relaxng)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
schema = etree.RelaxNG(etree.XML(b'<element name="root" xmlns="http://relaxng.org/ns/structure/1.0"><text/></element>'))
doc = etree.XML(b'<root>ok</root>')
print(schema.validate(doc))
PY
    validator_assert_contains "$tmpdir/out" 'True'
    ;;
  usage-python3-lxml-recover-parser)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
parser = etree.XMLParser(recover=True)
root = etree.fromstring(b'<root><item>ok</root>', parser)
print(root.xpath('string(item)'))
PY
    validator_assert_contains "$tmpdir/out" 'ok'
    ;;
  usage-xmlstarlet-namespace-select)
    cat >"$tmpdir/in.xml" <<'XML'
<root xmlns:a="urn:a"><a:item>namespaced</a:item></root>
XML
    xmlstarlet sel -N a=urn:a -t -v '/root/a:item' "$tmpdir/in.xml" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'namespaced'
    ;;
  usage-xmlstarlet-insert-attribute)
    printf '<root><item>1</item></root>' >"$tmpdir/in.xml"
    xmlstarlet ed -i '/root/item' -t attr -n status -v ok "$tmpdir/in.xml" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'status="ok"'
    ;;
  usage-xmlstarlet-delete-node)
    printf '<root><item>A</item><item>B</item></root>' >"$tmpdir/in.xml"
    xmlstarlet ed -d '/root/item[1]' "$tmpdir/in.xml" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<item>B</item>'
    if grep -Fq '<item>A</item>' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-xmlstarlet-c14n)
    printf '<root b="2" a="1"><item>ok</item></root>' >"$tmpdir/in.xml"
    xmlstarlet c14n "$tmpdir/in.xml" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<root a="1" b="2">'
    ;;
  usage-xmlstarlet-escape-text)
    printf 'a < b & c\n' | xmlstarlet esc | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'a &lt; b &amp; c'
    ;;
  *)
    printf 'unknown libxml extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
