#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r16-attrib-update-bulk-overwrite
# @title: lxml Element.attrib.update bulk-applies a dict and overwrites existing keys
# @description: Builds an element with two initial attributes, calls attrib.update with a dict that overwrites one and introduces two new keys, and asserts the resulting attribute map contains the union with the overwritten value taking precedence, exercising the MutableMapping-style update contract.
# @timeout: 60
# @tags: usage, xml, python, attribute
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

el = etree.fromstring(b'<x a="orig" b="keep"/>')
el.attrib.update({'a': 'new', 'c': '3', 'd': '4'})
print('attrs=' + str(sorted(el.attrib.items())))
print('len=' + str(len(el.attrib)))
print('serialized=' + etree.tostring(el).decode())
PY

validator_assert_contains "$tmpdir/out" "attrs=[('a', 'new'), ('b', 'keep'), ('c', '3'), ('d', '4')]"
validator_assert_contains "$tmpdir/out" 'len=4'
# Round-trip serialization must reflect the new value, not the original.
grep -E '^serialized=<x ' "$tmpdir/out" | grep -q 'a="new"'
