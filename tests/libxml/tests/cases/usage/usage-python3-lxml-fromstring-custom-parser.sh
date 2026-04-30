#!/usr/bin/env bash
# @testcase: usage-python3-lxml-fromstring-custom-parser
# @title: lxml fromstring with custom XMLParser settings
# @description: Parses XML through etree.fromstring using a custom XMLParser configured with remove_blank_text and remove_comments and verifies that whitespace-only text nodes and comments are stripped from the resulting tree.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xml = (
    b"<root>\n"
    b"  <!-- drop me -->\n"
    b"  <item>1</item>\n"
    b"  <item>2</item>\n"
    b"</root>\n"
)

parser = etree.XMLParser(remove_blank_text=True, remove_comments=True)
root = etree.fromstring(xml, parser)

assert root.tag == "root", root.tag
assert len(root) == 2, len(root)
for child in root:
    assert child.tag == "item", child.tag

# remove_comments must drop the comment node entirely.
comments = [n for n in root.iter() if isinstance(n, etree._Comment)]
assert comments == [], comments

# remove_blank_text strips whitespace-only text between siblings.
serialized = etree.tostring(root, encoding="unicode")
assert serialized == "<root><item>1</item><item>2</item></root>", serialized

print("children=" + str(len(root)))
print("serialized=" + serialized)
print("comments=" + str(len(comments)))
PY

validator_assert_contains "$tmpdir/out" 'children=2'
validator_assert_contains "$tmpdir/out" 'comments=0'
validator_assert_contains "$tmpdir/out" 'serialized=<root><item>1</item><item>2</item></root>'
