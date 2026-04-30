#!/usr/bin/env bash
# @testcase: usage-python3-lxml-iter-multi-tags
# @title: lxml etree.iter with multiple tag filter
# @description: Builds a mixed XML tree containing item, note, and meta elements, then calls Element.iter with a tuple of tag names and verifies the returned iterator yields elements of exactly the requested kinds in document order while skipping unrelated tags.
# @timeout: 180
# @tags: usage, xml, python, iter
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xml = (
    "<root>"
    "<item>1</item>"
    "<note>n1</note>"
    "<other>skip</other>"
    "<group>"
    "<item>2</item>"
    "<meta>m1</meta>"
    "<other>skip</other>"
    "<note>n2</note>"
    "</group>"
    "<item>3</item>"
    "</root>"
)
root = etree.fromstring(xml)

# Filter to two tags via tuple.
filtered = list(root.iter("item", "note"))
tags = [e.tag for e in filtered]
texts = [e.text for e in filtered]
assert tags == ["item", "note", "item", "note", "item"], tags
assert texts == ["1", "n1", "2", "n2", "3"], texts

# Three tags should additionally surface the meta element.
filtered3 = list(root.iter("item", "note", "meta"))
tags3 = [e.tag for e in filtered3]
assert tags3 == ["item", "note", "item", "meta", "note", "item"], tags3

# 'other' must never appear when we filter.
assert "other" not in tags, tags
assert "other" not in tags3, tags3

print("two-tags=" + ",".join(tags))
print("two-texts=" + ",".join(texts))
print("three-tags=" + ",".join(tags3))
PY

validator_assert_contains "$tmpdir/out" 'two-tags=item,note,item,note,item'
validator_assert_contains "$tmpdir/out" 'two-texts=1,n1,2,n2,3'
validator_assert_contains "$tmpdir/out" 'three-tags=item,note,item,meta,note,item'
