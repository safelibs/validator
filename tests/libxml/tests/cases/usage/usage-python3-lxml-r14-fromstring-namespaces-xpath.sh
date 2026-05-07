#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r14-fromstring-namespaces-xpath
# @title: lxml etree.fromstring + xpath namespaces map resolves prefixed element queries
# @description: Parses an XML document carrying a non-default namespace, runs xpath with an explicit namespaces map mapping a local prefix to the namespace URI, and asserts the query returns the expected element text under both the prefixed and Clark-notation traversal paths.
# @timeout: 60
# @tags: usage, xml, python, namespace, xpath
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

doc = etree.fromstring(b'''<root xmlns:a="urn:r14:alpha">
  <a:greeting>hello</a:greeting>
  <a:greeting>world</a:greeting>
</root>''')

ns = {'x': 'urn:r14:alpha'}
texts = doc.xpath('//x:greeting/text()', namespaces=ns)
print('texts=' + ','.join(texts))
print('count=' + str(len(texts)))

# Clark notation in iter:
clark = [el.text for el in doc.iter('{urn:r14:alpha}greeting')]
print('clark=' + ','.join(clark))
print('first_tag=' + doc[0].tag)
PY

validator_assert_contains "$tmpdir/out" 'texts=hello,world'
validator_assert_contains "$tmpdir/out" 'count=2'
validator_assert_contains "$tmpdir/out" 'clark=hello,world'
validator_assert_contains "$tmpdir/out" 'first_tag={urn:r14:alpha}greeting'
