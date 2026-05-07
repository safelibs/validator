#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r12-tostring-xml-declaration
# @title: lxml etree.tostring with xml_declaration=True emits the prolog with the requested encoding
# @description: Calls etree.tostring on a small element with xml_declaration=True and encoding='UTF-8', and asserts the serialized output begins with the canonical "<?xml version='1.0' encoding='UTF-8'?>" prolog followed by the element body.
# @timeout: 60
# @tags: usage, xml, python, serialize
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.Element('root')
etree.SubElement(doc, 'child').text = 'hello'
data = etree.tostring(doc, xml_declaration=True, encoding='UTF-8').decode('utf-8')
print('first_line=' + data.splitlines()[0])
print('contains_root=' + str('<root>' in data))
print('contains_child=' + str('<child>hello</child>' in data))
PY

validator_assert_contains "$tmpdir/out" "first_line=<?xml version='1.0' encoding='UTF-8'?>"
validator_assert_contains "$tmpdir/out" 'contains_root=True'
validator_assert_contains "$tmpdir/out" 'contains_child=True'
