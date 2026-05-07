#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r13-getroottree-getpath
# @title: lxml ElementTree.getpath returns the canonical XPath for a deeply nested element
# @description: Builds a small tree, locates a specific leaf via xpath, calls getroottree().getpath(elem), and asserts the returned XPath is the exact predicate-indexed path the leaf has in the document and that re-applying the path to the tree yields the same element.
# @timeout: 60
# @tags: usage, xml, python, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b'''<root>
  <section>
    <entry id="a">A</entry>
    <entry id="b">B</entry>
    <entry id="c">C</entry>
  </section>
  <section>
    <entry id="d">D</entry>
  </section>
</root>''')

target = doc.xpath("//entry[@id='c']")[0]
tree = target.getroottree()
path = tree.getpath(target)
print('path=' + path)

# Re-applying the path to the tree must return the same element.
again = tree.xpath(path)
print('len_again=' + str(len(again)))
print('same_id=' + str(again[0].get('id') == 'c'))
print('same_text=' + str(again[0].text == 'C'))
PY

validator_assert_contains "$tmpdir/out" 'path=/root/section[1]/entry[3]'
validator_assert_contains "$tmpdir/out" 'len_again=1'
validator_assert_contains "$tmpdir/out" 'same_id=True'
validator_assert_contains "$tmpdir/out" 'same_text=True'
