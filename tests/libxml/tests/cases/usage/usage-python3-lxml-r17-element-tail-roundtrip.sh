#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r17-element-tail-roundtrip
# @title: lxml Element .tail text is preserved across a tostring round-trip
# @description: Builds two sibling SubElements, sets the tail of the first to ' between ', serializes the tree, and asserts the tail text appears verbatim between the two child tags in the serialized form.
# @timeout: 60
# @tags: usage, xml, python, tail
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree
root = etree.Element('root')
a = etree.SubElement(root, 'a')
a.text = 'A'
a.tail = ' between '
b = etree.SubElement(root, 'b')
b.text = 'B'
print('s=' + etree.tostring(root, encoding='unicode'))
PY

validator_assert_contains "$tmpdir/out" 's=<root><a>A</a> between <b>B</b></root>'
