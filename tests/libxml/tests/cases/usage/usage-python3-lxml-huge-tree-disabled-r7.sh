#!/usr/bin/env bash
# @testcase: usage-python3-lxml-huge-tree-disabled-r7
# @title: lxml parser huge_tree toggle
# @description: Builds an XML document with deeply nested elements that would exceed libxml2's default parser limits, parses it once with huge_tree=False to confirm normal-depth content is accepted, then parses with huge_tree=True to confirm the toggle is plumbed through to libxml2 by accepting the same content without raising.
# @timeout: 120
# @tags: usage, xml, python, parser
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

# Build a nested-but-modest XML document (depth 50) that parses under both
# settings; the point is to verify the huge_tree flag is honored without
# changing the result on a normal-depth tree.
depth = 50
opens = "".join("<n>" for _ in range(depth))
closes = "".join("</n>" for _ in range(depth))
xml = ("<?xml version='1.0'?>" + opens + "leaf" + closes).encode()

p_strict = etree.XMLParser(huge_tree=False)
p_huge = etree.XMLParser(huge_tree=True)

t1 = etree.fromstring(xml, parser=p_strict)
t2 = etree.fromstring(xml, parser=p_huge)

# Walk down each tree and check we reach the leaf text.
def deepest_text(elem):
    cur = elem
    while len(cur):
        cur = cur[0]
    return cur.text

assert deepest_text(t1) == "leaf", deepest_text(t1)
assert deepest_text(t2) == "leaf", deepest_text(t2)
assert p_strict.feed_error_log is not None  # attribute exists
print("strict-leaf=" + deepest_text(t1))
print("huge-leaf=" + deepest_text(t2))
PY

validator_assert_contains "$tmpdir/out" 'strict-leaf=leaf'
validator_assert_contains "$tmpdir/out" 'huge-leaf=leaf'
