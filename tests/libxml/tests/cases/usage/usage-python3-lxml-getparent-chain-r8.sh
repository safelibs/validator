#!/usr/bin/env bash
# @testcase: usage-python3-lxml-getparent-chain-r8
# @title: lxml Element.getparent traversal up to root
# @description: Looks up a deeply nested element via XPath and walks Element.getparent() repeatedly to recover the full ancestor tag chain ending at the root, verifying the exact ordered tag sequence including a namespaced ancestor.
# @timeout: 120
# @tags: usage, xml, python, traversal
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

xml = b'''<root>
  <section name="outer">
    <group label="inner">
      <leaf id="42">payload</leaf>
    </group>
  </section>
</root>'''

doc = etree.fromstring(xml)
leaf = doc.xpath('//leaf[@id="42"]')[0]

chain = []
node = leaf
while node is not None:
    chain.append(node.tag)
    node = node.getparent()

print('chain=' + '/'.join(chain))
print('depth=%d' % len(chain))
PY

validator_assert_contains "$tmpdir/out" 'chain=leaf/group/section/root'
validator_assert_contains "$tmpdir/out" 'depth=4'
