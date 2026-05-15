#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r19-xpath-namespaces-arg-resolves-prefix
# @title: lxml Element.xpath with explicit namespaces dict resolves a custom prefix
# @description: Parses an XML document declaring a namespace under prefix 'a', then invokes element.xpath('//a:leaf/text()', namespaces={'a': '...'}) and asserts the returned list equals the two text values 'one' and 'two' — exercising lxml's namespace-aware XPath path.
# @timeout: 60
# @tags: usage, xml, python, xpath, namespaces, r19
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree
doc = etree.fromstring(b'''<r xmlns:a="urn:example:a">
  <a:leaf>one</a:leaf>
  <a:leaf>two</a:leaf>
</r>''')
got = doc.xpath('//a:leaf/text()', namespaces={'a': 'urn:example:a'})
print('values=' + ','.join(got))
PY

validator_assert_contains "$tmpdir/out" 'values=one,two'
