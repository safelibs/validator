#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

case "$case_id" in
  usage-xmlstarlet-select-attribute)
    xmlstarlet sel -t -v '/root/item[@id="b"]/@id' "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'b'
    ;;
  usage-xmlstarlet-count-nodes)
    xmlstarlet sel -t -v 'count(/root/item)' "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  usage-xmlstarlet-edit-update-attr)
    xmlstarlet ed -u '/root/group/@active' -v 'no' "$xml" >"$tmpdir/out.xml"
    validator_assert_contains "$tmpdir/out.xml" 'active="no"'
    ;;
  usage-xmlstarlet-edit-delete-node)
    xmlstarlet ed -d '/root/item[@id="a"]' "$xml" >"$tmpdir/out.xml"
    validator_assert_contains "$tmpdir/out.xml" 'beta'
    if grep -Fq 'alpha' "$tmpdir/out.xml"; then
      printf 'deleted node unexpectedly remained in XML output\n' >&2
      exit 1
    fi
    ;;
  usage-xmlstarlet-select-sum-value)
    xmlstarlet sel -t -v 'sum(/root/group/value)' "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-python3-lxml-itertext)
    python3 - "$xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
root = etree.parse(sys.argv[1]).getroot()
print('|'.join(text.strip() for text in root.itertext() if text.strip()))
PYCASE
    validator_assert_contains "$tmpdir/out" 'alpha|beta|3|hello-note'
    ;;
  usage-python3-lxml-fromstring-attribute)
    python3 - "$xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
text = open(sys.argv[1], 'rb').read()
root = etree.fromstring(text)
print(root.find('group').get('active'))
PYCASE
    validator_assert_contains "$tmpdir/out" 'yes'
    ;;
  usage-python3-lxml-item-id-join)
    python3 - "$xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
root = etree.parse(sys.argv[1]).getroot()
print(','.join(node.get('id') for node in root.findall('item')))
PYCASE
    validator_assert_contains "$tmpdir/out" 'a,b'
    ;;
  usage-python3-lxml-xpath-count)
    python3 - "$xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
root = etree.parse(sys.argv[1])
print(int(root.xpath('count(/root/item)')))
PYCASE
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  usage-xmlstarlet-select-namespace-note)
    xmlstarlet sel -N h='urn:hello' -t -v '/root/h:note' "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'hello-note'
    ;;
  *)
    printf 'unknown libxml further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
