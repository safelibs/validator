#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r10-addnext-addprevious
# @title: lxml Element addnext and addprevious insert siblings
# @description: Builds a sibling chain via Element.addnext() and Element.addprevious() relative to a pivot element, then asserts the resulting child order is exactly previous, pivot, next.
# @timeout: 60
# @tags: usage, xml, python, mutation
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.Element('root')
pivot = etree.SubElement(root, 'pivot')

before = etree.Element('before')
after = etree.Element('after')

pivot.addprevious(before)
pivot.addnext(after)

tags = [child.tag for child in root]
print('tags=' + ','.join(tags))
print('count=' + str(len(root)))
PY

validator_assert_contains "$tmpdir/out" 'tags=before,pivot,after'
validator_assert_contains "$tmpdir/out" 'count=3'
