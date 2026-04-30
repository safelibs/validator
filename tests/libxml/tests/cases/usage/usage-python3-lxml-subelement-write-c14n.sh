#!/usr/bin/env bash
# @testcase: usage-python3-lxml-subelement-write-c14n
# @title: lxml SubElement and ElementTree write_c14n
# @description: Builds a tree with etree.SubElement and serializes it to disk via ElementTree.write with method="c14n", then verifies the exact canonical bytes including alphabetic attribute ordering.
# @timeout: 120
# @tags: usage, xml, python, c14n, serialize
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-subelement-write-c14n"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out.xml" <<'PY'
import sys
from lxml import etree
root = etree.Element('root')
item = etree.SubElement(root, 'item', b='2', a='1')
item.text = 'x'
tree = etree.ElementTree(root)
tree.write(sys.argv[1], method='c14n')
PY

expected='<root><item a="1" b="2">x</item></root>'
got=$(cat "$tmpdir/out.xml")
[[ "$got" == "$expected" ]] || {
  printf 'c14n write mismatch:\nexpected: %s\nactual:   %s\n' "$expected" "$got" >&2
  exit 1
}
