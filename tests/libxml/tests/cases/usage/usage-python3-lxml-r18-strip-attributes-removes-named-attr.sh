#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r18-strip-attributes-removes-named-attr
# @title: lxml etree.strip_attributes removes the named attribute from all matching elements
# @description: Builds a tree with multiple elements that carry a removable 'tmp' attribute, invokes etree.strip_attributes(tree, 'tmp'), and asserts no element retains the attribute while leaving other attributes intact.
# @timeout: 60
# @tags: usage, xml, python, attributes, r18
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.fromstring(b'<r><a tmp="1" keep="x"/><b tmp="2"/><c keep="y"/></r>')
etree.strip_attributes(root, 'tmp')
tmp_count = sum(1 for el in root.iter() if 'tmp' in el.attrib)
keep_count = sum(1 for el in root.iter() if 'keep' in el.attrib)
print('tmp_count=' + str(tmp_count))
print('keep_count=' + str(keep_count))
PY

validator_assert_contains "$tmpdir/out" 'tmp_count=0'
validator_assert_contains "$tmpdir/out" 'keep_count=2'
