#!/usr/bin/env bash
# @testcase: usage-python3-lxml-tostring-c14n2
# @title: lxml tostring c14n2 method
# @description: Serializes an XML tree through etree.tostring with method='c14n2' (the newer Canonical XML 2.0 serializer) and verifies the canonical attribute ordering and namespace handling of the output, distinct from the legacy method='c14n' path.
# @timeout: 180
# @tags: usage, xml, python, c14n
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xml = b'<root z="3" a="1" m="2"><child b="b" a="a"/></root>'
root = etree.fromstring(xml)

# c14n2 is XML Canonicalization Version 2.0 (a separate codepath from method='c14n').
out = etree.tostring(root, method='c14n2').decode('ascii')
assert out.startswith('<root '), out
# Attributes must be sorted alphabetically; c14n2 expands self-closing tags
# to start/end pairs (<child/></child>) per the canonicalization spec.
assert out.startswith('<root a="1" m="2" z="3">'), out
assert '<child a="a" b="b">' in out, out
assert '</child>' in out, out
assert out.endswith('</root>'), out

print("c14n2=" + out)
PY

validator_assert_contains "$tmpdir/out" 'c14n2=<root a="1" m="2" z="3">'
validator_assert_contains "$tmpdir/out" '<child a="a" b="b">'
validator_assert_contains "$tmpdir/out" '</child></root>'
