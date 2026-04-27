#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/doc.xml"
cat >"$xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root xmlns:m="urn:meta">
  <item id="a" weight="2">alpha</item>
  <item id="b" weight="3">beta</item>
  <item id="c" weight="5">gamma</item>
  <m:tag>meta-tag</m:tag>
</root>
XML

case "$case_id" in
  usage-python3-lxml-xpath-last-item-text)
    XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
print(tree.xpath('string(/root/item[last()])'))
PYCASE
    validator_assert_contains "$tmpdir/out" 'gamma'
    ;;
  usage-python3-lxml-xpath-sum-weight)
    XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
print(int(tree.xpath('sum(/root/item/@weight)')))
PYCASE
    validator_assert_contains "$tmpdir/out" '10'
    ;;
  usage-python3-lxml-getroottree-tag)
    XML_PATH="$xml" python3 >"$tmpdir/out" <<'PYCASE'
import os
from lxml import etree
tree = etree.parse(os.environ['XML_PATH'])
node = tree.xpath('/root/item[2]')[0]
print(node.getroottree().getroot().tag)
PYCASE
    validator_assert_contains "$tmpdir/out" 'root'
    ;;
  usage-python3-lxml-deepcopy-text)
    python3 >"$tmpdir/out" <<'PYCASE'
import copy
from lxml import etree
root = etree.XML(b'<root><item>alpha</item></root>')
clone = copy.deepcopy(root)
clone.find('item').text = 'beta'
print(root.find('item').text, clone.find('item').text)
PYCASE
    validator_assert_contains "$tmpdir/out" 'alpha beta'
    ;;
  usage-python3-lxml-attrib-items-list)
    python3 >"$tmpdir/out" <<'PYCASE'
from lxml import etree
node = etree.XML(b'<item id="a" weight="3"/>')
pairs = sorted(node.attrib.items())
print(','.join('{}={}'.format(k, v) for k, v in pairs))
PYCASE
    validator_assert_contains "$tmpdir/out" 'id=a,weight=3'
    ;;
  usage-python3-lxml-canonicalize-c14n)
    python3 >"$tmpdir/out" <<'PYCASE'
from lxml import etree
xml = '<root b="2" a="1"><item>ok</item></root>'
print(etree.canonicalize(xml))
PYCASE
    validator_assert_contains "$tmpdir/out" '<root a="1" b="2">'
    ;;
  usage-xmlstarlet-pyx-output)
    xmlstarlet pyx "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '(root'
    validator_assert_contains "$tmpdir/out" '-alpha'
    ;;
  usage-xmlstarlet-validate-well-formed)
    xmlstarlet val -w "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'valid'
    ;;
  usage-xmlstarlet-edit-rename-item)
    xmlstarlet ed -r '/root/item[1]' -v entry "$xml" >"$tmpdir/out.xml"
    validator_assert_contains "$tmpdir/out.xml" '<entry id="a"'
    if grep -Fq '<item id="a"' "$tmpdir/out.xml"; then
      printf 'rename left old item element behind\n' >&2
      exit 1
    fi
    ;;
  usage-xmlstarlet-select-namespaced-tag)
    xmlstarlet sel -N m='urn:meta' -t -v 'string(/root/m:tag)' "$xml" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'meta-tag'
    ;;
  *)
    printf 'unknown libxml tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
