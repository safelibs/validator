#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r14-iselement-detection
# @title: lxml etree.iselement returns True for Element objects and False for non-elements
# @description: Calls etree.iselement on an Element, an ElementTree, a string, and None, and asserts only the Element returns True. This pins the public type-check predicate behavior used by libraries that bridge lxml objects.
# @timeout: 60
# @tags: usage, xml, python, predicate
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b'<root><a/></root>')
tree = doc.getroottree()

print('elem=' + str(etree.iselement(doc)))
print('child=' + str(etree.iselement(doc[0])))
print('tree=' + str(etree.iselement(tree)))
print('string=' + str(etree.iselement('not an element')))
print('none=' + str(etree.iselement(None)))
print('list=' + str(etree.iselement([doc])))
PY

validator_assert_contains "$tmpdir/out" 'elem=True'
validator_assert_contains "$tmpdir/out" 'child=True'
validator_assert_contains "$tmpdir/out" 'tree=False'
validator_assert_contains "$tmpdir/out" 'string=False'
validator_assert_contains "$tmpdir/out" 'none=False'
validator_assert_contains "$tmpdir/out" 'list=False'
