#!/usr/bin/env bash
# @testcase: usage-python3-lxml-iterancestors-chain
# @title: lxml iterancestors traversal
# @description: Builds a four-level nested XML tree, locates the deepest element via XPath, and walks up the ancestor chain through Element.iterancestors verifying both the unfiltered ancestor sequence and a tag-filtered traversal that yields only matching ancestors in upward order.
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
    "<section id='a'>"
    "<group id='g1'>"
    "<item id='leaf'>x</item>"
    "</group>"
    "</section>"
    "</root>"
)
root = etree.fromstring(xml)

leaf = root.xpath("//item[@id='leaf']")[0]
assert leaf.tag == "item", leaf.tag

# Unfiltered ancestor walk: should be group -> section -> root, in that order.
ancestors = list(leaf.iterancestors())
ancestor_tags = [a.tag for a in ancestors]
assert ancestor_tags == ["group", "section", "root"], ancestor_tags

# Tag-filtered ancestor walk: only section and root should remain.
filtered = [a.tag for a in leaf.iterancestors(("section", "root"))]
assert filtered == ["section", "root"], filtered

# Single-tag filter yields exactly one element.
single = [a for a in leaf.iterancestors("group")]
assert len(single) == 1, single
assert single[0].get("id") == "g1", single[0].get("id")

print("ancestors=" + ",".join(ancestor_tags))
print("filtered=" + ",".join(filtered))
print("single-id=" + single[0].get("id"))
PY

validator_assert_contains "$tmpdir/out" 'ancestors=group,section,root'
validator_assert_contains "$tmpdir/out" 'filtered=section,root'
validator_assert_contains "$tmpdir/out" 'single-id=g1'
