#!/usr/bin/env bash
# @testcase: usage-python3-lxml-comment-insert-position
# @title: lxml etree.Comment insertion at index
# @description: Creates a Comment node through etree.Comment(text), inserts it at a specific child index of a parent element using insert(), and verifies the serialized tree places the comment exactly between the targeted siblings without disturbing surrounding nodes.
# @timeout: 180
# @tags: usage, xml, python, comment
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.Element("root")
etree.SubElement(root, "a").text = "1"
etree.SubElement(root, "b").text = "2"
etree.SubElement(root, "c").text = "3"

comment = etree.Comment(" inserted ")
# Insert between <a> (index 0) and <b> (index 1).
root.insert(1, comment)

children = list(root)
assert len(children) == 4, len(children)
assert children[0].tag == "a"
assert children[1].tag is etree.Comment
assert children[1].text == " inserted "
assert children[2].tag == "b"
assert children[3].tag == "c"

xml = etree.tostring(root, encoding="unicode")
assert "<a>1</a><!-- inserted --><b>2</b><c>3</c>" in xml, xml

print("xml=" + xml)
print("len=" + str(len(children)))
print("comment-text=" + children[1].text)
PY

validator_assert_contains "$tmpdir/out" '<a>1</a><!-- inserted --><b>2</b><c>3</c>'
validator_assert_contains "$tmpdir/out" 'len=4'
validator_assert_contains "$tmpdir/out" 'comment-text= inserted '
