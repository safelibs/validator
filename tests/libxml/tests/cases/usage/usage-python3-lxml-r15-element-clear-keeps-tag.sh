#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r15-element-clear-keeps-tag
# @title: lxml Element.clear() drops children, attributes, and text but preserves the element tag
# @description: Builds an Element with text, attributes, and child nodes, calls clear() on it, and asserts the tag is unchanged while text becomes None, the attribute map is empty, and the children list has length 0.
# @timeout: 60
# @tags: usage, xml, python, clear
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b'<root attr="val">leading<a/><b/>between</root>')
print('before_tag=' + doc.tag)
print('before_text=' + repr(doc.text))
print('before_attrs=' + str(sorted(doc.attrib.items())))
print('before_count=' + str(len(doc)))

doc.clear()
print('after_tag=' + doc.tag)
print('after_text=' + str(doc.text))
print('after_attrs=' + str(sorted(doc.attrib.items())))
print('after_count=' + str(len(doc)))
PY

validator_assert_contains "$tmpdir/out" "before_tag=root"
validator_assert_contains "$tmpdir/out" "before_text='leading'"
validator_assert_contains "$tmpdir/out" "before_attrs=[('attr', 'val')]"
validator_assert_contains "$tmpdir/out" "before_count=2"
validator_assert_contains "$tmpdir/out" "after_tag=root"
validator_assert_contains "$tmpdir/out" "after_text=None"
validator_assert_contains "$tmpdir/out" "after_attrs=[]"
validator_assert_contains "$tmpdir/out" "after_count=0"
