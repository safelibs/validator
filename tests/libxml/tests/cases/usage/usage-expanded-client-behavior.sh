#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/doc.xml"
cat >"$xml" <<'XML'
<root xmlns:ns="urn:test">
  <item id="a">alpha</item>
  <item id="b">beta</item>
  <ns:note>namespaced</ns:note>
</root>
XML

case "$case_id" in
  usage-python3-lxml-attribute-set)
    XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
tree.getroot().set('status', 'ok')
print(tree.getroot().get('status'))
PYCASE
    validator_assert_contains "$tmpdir/out" 'ok'
    ;;
  usage-python3-lxml-nsmap-lookup)
    XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
value = tree.xpath('string(//ns:note)', namespaces={'ns': 'urn:test'})
print(value)
PYCASE
    validator_assert_contains "$tmpdir/out" 'namespaced'
    ;;
  usage-python3-lxml-tostring-pretty)
    XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
text = etree.tostring(tree, pretty_print=True).decode('utf-8')
print(text, end='')
PYCASE
    validator_assert_contains "$tmpdir/out" '<item id="a">alpha</item>'
    ;;
  usage-python3-lxml-xpath-string-value)
    XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
print(tree.xpath('string(/root/item[@id="b"])'))
PYCASE
    validator_assert_contains "$tmpdir/out" 'beta'
    ;;
  usage-python3-lxml-iterfind-count)
    XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
print(len(list(tree.iterfind('.//item'))))
PYCASE
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  usage-xmlstarlet-edit-add-attribute)
    xmlstarlet ed -s '/root/item[1]' -t attr -n kind -v primary "$xml" >"$tmpdir/out.xml"
    xmlstarlet sel -t -v '/root/item[1]/@kind' "$tmpdir/out.xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'primary'
    ;;
  usage-xmlstarlet-edit-append-node)
    xmlstarlet ed -s '/root' -t elem -n extra -v tail "$xml" >"$tmpdir/out.xml"
    xmlstarlet sel -t -v 'string(/root/extra)' "$tmpdir/out.xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'tail'
    ;;
  usage-xmlstarlet-select-attribute-value)
    xmlstarlet sel -t -v '/root/item[2]/@id' "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'b'
    ;;
  usage-xmlstarlet-c14n-root)
    xmlstarlet c14n "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '<ns:note>namespaced</ns:note>'
    ;;
  usage-xmlstarlet-select-text-count)
    xmlstarlet sel -t -v 'count(/root/item)' "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  *)
    printf 'unknown libxml expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
