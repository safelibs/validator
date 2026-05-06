#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r10-tostring-standalone-decl
# @title: lxml etree.tostring writes XML decl with standalone='yes'
# @description: Serializes an ElementTree with xml_declaration=True and standalone=True, and asserts the emitted prolog includes encoding='UTF-8' and standalone='yes'.
# @timeout: 60
# @tags: usage, xml, python, serialize
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out.xml" <<'PY'
import sys
from lxml import etree

root = etree.Element('root')
etree.SubElement(root, 'item').text = 'value'
tree = etree.ElementTree(root)
data = etree.tostring(tree, xml_declaration=True, encoding='UTF-8', standalone=True)
sys.stdout.buffer.write(data)
PY

validator_assert_contains "$tmpdir/out.xml" "<?xml"
validator_assert_contains "$tmpdir/out.xml" "encoding='UTF-8'"
validator_assert_contains "$tmpdir/out.xml" "standalone='yes'"
validator_assert_contains "$tmpdir/out.xml" "<root>"
validator_assert_contains "$tmpdir/out.xml" "<item>value</item>"
