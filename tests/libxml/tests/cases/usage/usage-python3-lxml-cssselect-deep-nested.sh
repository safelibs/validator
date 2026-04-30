#!/usr/bin/env bash
# @testcase: usage-python3-lxml-cssselect-deep-nested
# @title: lxml CSSSelector deep nested
# @description: Builds a CSSSelector and matches deeply nested elements through descendant selectors, verifying the exact match count and text values returned for a multi-level XML tree.
# @timeout: 120
# @tags: usage, xml, python, cssselect
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-cssselect-deep-nested"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' >"$tmpdir/out"
from lxml import etree
from lxml.cssselect import CSSSelector
xml = b"""
<root>
  <section class="outer">
    <group>
      <item class="hit">one</item>
      <nested>
        <item class="hit">two</item>
      </nested>
    </group>
    <item class="miss">no</item>
  </section>
  <section class="other">
    <group>
      <item class="hit">three</item>
    </group>
  </section>
</root>
"""
root = etree.fromstring(xml)
sel = CSSSelector('section.outer item.hit')
hits = sel(root)
print("count=%d" % len(hits))
print("texts=%s" % ",".join(h.text for h in hits))
PY

validator_assert_contains "$tmpdir/out" 'count=2'
validator_assert_contains "$tmpdir/out" 'texts=one,two'
