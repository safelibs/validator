#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-lxml-fromstring-bytes)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.fromstring(b'<root><item>alpha</item></root>')
print(root.findtext('item'))
PY
    validator_assert_contains "$tmpdir/out" 'alpha'
    ;;
  usage-python3-lxml-xmlid-map)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root, ids = etree.XMLID(b'<root><item id="node-a">alpha</item></root>')
print(ids['node-a'].text)
PY
    validator_assert_contains "$tmpdir/out" 'alpha'
    ;;
  usage-python3-lxml-qname-localname)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
qname = etree.QName('urn:test', 'item')
print(qname.localname)
PY
    validator_assert_contains "$tmpdir/out" 'item'
    ;;
  usage-python3-lxml-elementpath-findtext)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><group><item>beta</item></group></root>')
print(root.findtext('group/item'))
PY
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-python3-lxml-cdata-serialize)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.Element('root')
root.text = etree.CDATA('alpha<beta>')
print(etree.tostring(root).decode())
PY
    validator_assert_contains "$tmpdir/out" '<![CDATA[alpha<beta>]]>'
    ;;
  usage-python3-lxml-tostring-pretty)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><item>alpha</item></root>')
print(etree.tostring(root, pretty_print=True).decode())
PY
    validator_assert_contains "$tmpdir/out" '<item>alpha</item>'
    ;;
  usage-xmlstarlet-update-attribute)
    printf '<root><item status="old">A</item></root>' >"$tmpdir/in.xml"
    xmlstarlet ed -u '/root/item/@status' -v 'ok' "$tmpdir/in.xml" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'status="ok"'
    ;;
  usage-xmlstarlet-concat-text)
    printf '<root><item>A</item><item>B</item></root>' >"$tmpdir/in.xml"
    xmlstarlet sel -t -m '/root/item' -v . -o ',' "$tmpdir/in.xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'A,B,'
    ;;
  usage-xmlstarlet-omit-decl-format)
    printf '<root><item>A</item></root>' >"$tmpdir/in.xml"
    xmlstarlet sel -t -c '/root' "$tmpdir/in.xml" >"$tmpdir/out"
    if grep -Fq '<?xml' "$tmpdir/out"; then exit 1; fi
    validator_assert_contains "$tmpdir/out" '<item>A</item>'
    ;;
  usage-xmlstarlet-append-attribute)
    printf '<root><item>A</item></root>' >"$tmpdir/in.xml"
    xmlstarlet ed -i '/root/item' -t attr -n code -v 'A1' "$tmpdir/in.xml" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'code="A1"'
    ;;
  *)
    printf 'unknown libxml even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
