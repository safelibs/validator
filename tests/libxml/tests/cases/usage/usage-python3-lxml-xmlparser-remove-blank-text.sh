#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xmlparser-remove-blank-text
# @title: lxml XMLParser remove_blank_text
# @description: Parses an indented XML document with lxml.etree.XMLParser(remove_blank_text=True) and verifies that ignorable whitespace text nodes are dropped, leaving exactly the element children expected with no whitespace .text or .tail.
# @timeout: 120
# @tags: usage, xml, python, parser
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xmlparser-remove-blank-text"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<root>
    <item>alpha</item>
    <item>beta</item>
    <item>gamma</item>
</root>
XML

python3 - "$tmpdir/in.xml" <<'PY' >"$tmpdir/out"
import sys
from lxml import etree
parser = etree.XMLParser(remove_blank_text=True)
tree = etree.parse(sys.argv[1], parser)
root = tree.getroot()
print("children=%d" % len(root))
print("root_text=%r" % root.text)
items = list(root)
print("texts=%s" % ",".join(it.text for it in items))
print("tails=%s" % ",".join(repr(it.tail) for it in items))
PY

validator_assert_contains "$tmpdir/out" 'children=3'
validator_assert_contains "$tmpdir/out" 'root_text=None'
validator_assert_contains "$tmpdir/out" 'texts=alpha,beta,gamma'
# Every item.tail should be None (whitespace stripped).
validator_assert_contains "$tmpdir/out" 'tails=None,None,None'
