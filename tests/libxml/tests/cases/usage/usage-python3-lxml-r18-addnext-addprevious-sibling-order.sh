#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r18-addnext-addprevious-sibling-order
# @title: lxml _Element addnext and addprevious place siblings at the expected positions
# @description: Constructs an element list, uses addnext and addprevious to insert siblings around a middle element, and asserts the resulting in-order tag sequence matches the expected ordering pinned by the API contract.
# @timeout: 60
# @tags: usage, xml, python, siblings, r18
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.Element('r')
b = etree.SubElement(root, 'b')
b.addprevious(etree.Element('a'))
b.addnext(etree.Element('c'))
tags = ','.join(child.tag for child in root)
print('tags=' + tags)
PY

validator_assert_contains "$tmpdir/out" 'tags=a,b,c'
