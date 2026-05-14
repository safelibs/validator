#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r17-subelement-text-tostring-shape
# @title: lxml etree.SubElement with .text yields the expected serialized shape
# @description: Builds an Element with two SubElement children carrying text, serializes via etree.tostring with encoding='unicode', and asserts the result contains both child tags with their text bodies in document order — exercising the basic tree construction + serialization path.
# @timeout: 60
# @tags: usage, xml, python, build
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.Element('root')
a = etree.SubElement(root, 'a')
a.text = 'alpha'
b = etree.SubElement(root, 'b')
b.text = 'bravo'
s = etree.tostring(root, encoding='unicode')
print('s=' + s)
PY

validator_assert_contains "$tmpdir/out" 's=<root><a>alpha</a><b>bravo</b></root>'
