#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpath-compiled-reuse-r8
# @title: lxml etree.XPath compiled expression reused across documents
# @description: Compiles an etree.XPath expression with namespace bindings once and applies it to two distinct parsed documents, verifying that the same compiled XPath instance returns the per-document node counts and string values without reparsing the expression.
# @timeout: 120
# @tags: usage, xml, python, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc1 = etree.fromstring(b'''<root xmlns:m="urn:m">
  <m:item id="x">one</m:item>
  <m:item id="y">two</m:item>
</root>''')
doc2 = etree.fromstring(b'''<root xmlns:m="urn:m">
  <m:item id="z">solo</m:item>
</root>''')

count_xp = etree.XPath('count(//m:item)', namespaces={'m': 'urn:m'})
first_text_xp = etree.XPath('string((//m:item)[1])', namespaces={'m': 'urn:m'})

c1 = int(count_xp(doc1))
c2 = int(count_xp(doc2))
t1 = first_text_xp(doc1)
t2 = first_text_xp(doc2)

print('c1=%d' % c1)
print('c2=%d' % c2)
print('t1=%s' % t1)
print('t2=%s' % t2)
PY

validator_assert_contains "$tmpdir/out" 'c1=2'
validator_assert_contains "$tmpdir/out" 'c2=1'
validator_assert_contains "$tmpdir/out" 't1=one'
validator_assert_contains "$tmpdir/out" 't2=solo'
