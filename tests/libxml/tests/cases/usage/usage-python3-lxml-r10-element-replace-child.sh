#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r10-element-replace-child
# @title: lxml Element.replace swaps a child in place preserving order
# @description: Parses a parent with three children, calls Element.replace() to swap the middle child for a freshly built element, and asserts the new tag appears at the original position with siblings intact.
# @timeout: 60
# @tags: usage, xml, python, mutation
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.fromstring(
    b"<root><a/><b id='old'/><c/></root>"
)
old = root.find('b')
new = etree.SubElement(etree.Element('placeholder'), 'replacement')
new.set('id', 'new')
root.replace(old, new)

tags = [child.tag for child in root]
print('tags=' + ','.join(tags))
print('middle_id=' + root[1].get('id'))
print('count=' + str(len(root)))
PY

validator_assert_contains "$tmpdir/out" 'tags=a,replacement,c'
validator_assert_contains "$tmpdir/out" 'middle_id=new'
validator_assert_contains "$tmpdir/out" 'count=3'
