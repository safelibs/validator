#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r13-cssselect-attribute-equals
# @title: lxml.cssselect.CSSSelector matches attribute-equals selectors against an XML tree
# @description: Builds a small XML fragment of mixed-priority items and applies a compiled CSSSelector for "item[priority='high']" via lxml.cssselect, asserts the returned matches contain only the two high-priority items and their text bodies are recovered intact in document order.
# @timeout: 60
# @tags: usage, xml, python, cssselect
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree
from lxml.cssselect import CSSSelector

doc = etree.fromstring(b'''<root>
  <item priority="low">alpha</item>
  <item priority="high">bravo</item>
  <item priority="low">charlie</item>
  <item priority="high">delta</item>
</root>''')

sel = CSSSelector("item[priority='high']")
matches = sel(doc)
print('count=' + str(len(matches)))
print('texts=' + ','.join(m.text for m in matches))
print('priorities=' + ','.join(m.get('priority') for m in matches))
PY

validator_assert_contains "$tmpdir/out" 'count=2'
validator_assert_contains "$tmpdir/out" 'texts=bravo,delta'
validator_assert_contains "$tmpdir/out" 'priorities=high,high'
