#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-lxml-attribute-update)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><item/></root>')
root.find("item").set("status", "ok")
print(etree.tostring(root).decode())
PY
    validator_assert_contains "$tmpdir/out" 'status="ok"'
    ;;
  usage-python3-lxml-comment-node)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.Element("root")
root.append(etree.Comment("note"))
print(etree.tostring(root).decode())
PY
    validator_assert_contains "$tmpdir/out" '<!--note-->'
    ;;
  usage-python3-lxml-xpath-string)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><item>alpha</item><item>beta</item></root>')
print(root.xpath('concat(/root/item[1], "-", /root/item[2])'))
PY
    validator_assert_contains "$tmpdir/out" 'alpha-beta'
    ;;
  usage-python3-lxml-bytesio-parse)
    python3 - <<'PY' | tee "$tmpdir/out"
from io import BytesIO
from lxml import etree
root = etree.parse(BytesIO(b'<root><item>ok</item></root>')).getroot()
print(root.xpath('string(item)'))
PY
    validator_assert_contains "$tmpdir/out" 'ok'
    ;;
  usage-python3-lxml-namespace-attribute)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root xmlns:a="urn:a"><item a:status="ok"/></root>')
print(root.xpath('string(/root/item/@a:status)', namespaces={'a': 'urn:a'}))
PY
    validator_assert_contains "$tmpdir/out" 'ok'
    ;;
  usage-python3-lxml-itertext-join)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root>alpha<item>beta</item>gamma</root>')
print("|".join(root.itertext()))
PY
    validator_assert_contains "$tmpdir/out" 'alpha|beta|gamma'
    ;;
  usage-python3-lxml-tree-write)
    python3 - <<'PY' "$tmpdir/out.xml"
from lxml import etree
import sys
tree = etree.ElementTree(etree.XML(b'<root><item>file</item></root>'))
tree.write(sys.argv[1], encoding="utf-8", xml_declaration=True)
print("written")
PY
    validator_assert_contains "$tmpdir/out.xml" '<?xml'
    validator_assert_contains "$tmpdir/out.xml" '<item>file</item>'
    ;;
  usage-python3-lxml-strip-text)
    python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root>  spaced text  </root>')
print(root.xpath('normalize-space(/root)'))
PY
    validator_assert_contains "$tmpdir/out" 'spaced text'
    ;;
  usage-xmlstarlet-move-node)
    printf '<root><group/><item>A</item></root>' >"$tmpdir/in.xml"
    xmlstarlet ed -m '/root/item' '/root/group' "$tmpdir/in.xml" | tee "$tmpdir/out"
    xmlstarlet sel -t -v 'string(/root/group/item)' "$tmpdir/out" >"$tmpdir/value"
    grep -Fxq 'A' "$tmpdir/value"
    ;;
  usage-xmlstarlet-delete-attribute)
    printf '<root><item status="old">A</item></root>' >"$tmpdir/in.xml"
    xmlstarlet ed -d '/root/item/@status' "$tmpdir/in.xml" | tee "$tmpdir/out"
    if grep -Fq 'status=' "$tmpdir/out"; then
      printf 'attribute delete unexpectedly retained status attribute\n' >&2
      exit 1
    fi
    validator_assert_contains "$tmpdir/out" '<item>A</item>'
    ;;
  *)
    printf 'unknown libxml additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
