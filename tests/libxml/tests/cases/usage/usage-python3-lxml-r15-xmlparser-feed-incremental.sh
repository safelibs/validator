#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r15-xmlparser-feed-incremental
# @title: lxml etree.XMLParser.feed accepts the document in chunks and returns the root via close()
# @description: Drives an etree.XMLParser by feeding the document in five disjoint byte slices via parser.feed(), then calls parser.close() and asserts the returned Element has the expected root tag, child count, and serialized form, demonstrating incremental parsing.
# @timeout: 60
# @tags: usage, xml, python, parser, feed
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

p = etree.XMLParser()
for chunk in (b'<root>', b'<a>1</a>', b'<b>', b'2', b'</b></root>'):
    p.feed(chunk)
root = p.close()

print('tag=' + root.tag)
print('count=' + str(len(root)))
print('serialized=' + etree.tostring(root, encoding='unicode'))
print('child0=' + root[0].tag + ':' + (root[0].text or ''))
print('child1=' + root[1].tag + ':' + (root[1].text or ''))
PY

validator_assert_contains "$tmpdir/out" 'tag=root'
validator_assert_contains "$tmpdir/out" 'count=2'
validator_assert_contains "$tmpdir/out" 'serialized=<root><a>1</a><b>2</b></root>'
validator_assert_contains "$tmpdir/out" 'child0=a:1'
validator_assert_contains "$tmpdir/out" 'child1=b:2'
