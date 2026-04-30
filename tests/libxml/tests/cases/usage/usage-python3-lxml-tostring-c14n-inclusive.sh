#!/usr/bin/env bash
# @testcase: usage-python3-lxml-tostring-c14n-inclusive
# @title: lxml tostring inclusive vs exclusive C14N
# @description: Serializes a subtree through etree.tostring with method='c14n' both inclusively and exclusively, then verifies that inclusive C14N retains ancestor-declared but unused namespaces while exclusive C14N drops them.
# @timeout: 180
# @tags: usage, xml, python, c14n
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xml = (
    '<root xmlns:a="urn:a" xmlns:b="urn:b" xmlns:c="urn:c">'
    '<a:item>X</a:item>'
    '</root>'
)
root = etree.fromstring(xml)
inner = root[0]

inclusive = etree.tostring(inner, method='c14n', exclusive=False).decode('ascii')
exclusive = etree.tostring(inner, method='c14n', exclusive=True).decode('ascii')

# Inclusive C14N keeps all ancestor namespace declarations visible at the node.
for needle in ('xmlns:a="urn:a"', 'xmlns:b="urn:b"', 'xmlns:c="urn:c"'):
    assert needle in inclusive, (needle, inclusive)

# Exclusive C14N keeps only the namespace actually used (a:item).
assert 'xmlns:a="urn:a"' in exclusive, exclusive
assert 'urn:b' not in exclusive, exclusive
assert 'urn:c' not in exclusive, exclusive

print("inclusive=" + inclusive)
print("exclusive=" + exclusive)
PY

validator_assert_contains "$tmpdir/out" 'inclusive='
validator_assert_contains "$tmpdir/out" 'xmlns:b="urn:b"'
validator_assert_contains "$tmpdir/out" 'xmlns:c="urn:c"'
validator_assert_contains "$tmpdir/out" 'exclusive=<a:item xmlns:a="urn:a">X</a:item>'
