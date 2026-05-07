#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r15-element-replace-drops-tail
# @title: lxml Element.replace swaps a child element and drops the replaced node's tail text
# @description: Builds a parent with two children where the first child carries tail text, calls parent.replace(old, new), and asserts the new element occupies the old position, the new element's tail is empty (the replaced node's tail is dropped), and the serialized output reflects the swap with the trailing tail removed.
# @timeout: 60
# @tags: usage, xml, python, replace
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b'<root>head<old>x</old>tail<keep>y</keep>end</root>')
old = doc.find('old')
new = etree.Element('new')
new.text = 'replacement'
doc.replace(old, new)

print('serialized=' + etree.tostring(doc, encoding='unicode'))
print('first_child_tag=' + doc[0].tag)
print('first_child_text=' + (doc[0].text or ''))
print('first_child_tail=' + (doc[0].tail or ''))
print('count=' + str(len(doc)))
PY

validator_assert_contains "$tmpdir/out" 'serialized=<root>head<new>replacement</new><keep>y</keep>end</root>'
validator_assert_contains "$tmpdir/out" 'first_child_tag=new'
validator_assert_contains "$tmpdir/out" 'first_child_text=replacement'
validator_assert_contains "$tmpdir/out" 'first_child_tail='
validator_assert_contains "$tmpdir/out" 'count=2'
