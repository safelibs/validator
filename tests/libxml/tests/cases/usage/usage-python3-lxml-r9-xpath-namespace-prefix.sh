#!/usr/bin/env bash
# @testcase: usage-python3-lxml-r9-xpath-namespace-prefix
# @title: lxml XPath honours namespace prefix mapping
# @description: Parses a document with a default namespace and runs an XPath using a custom prefix mapping, asserting the namespaced element is selected.
# @timeout: 60
# @tags: usage, python3-lxml, xpath, namespace
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from lxml import etree
xml = b"""<root xmlns='http://example.com/ns'>
  <thing id='one'/>
  <thing id='two'/>
</root>"""
root = etree.fromstring(xml)
ns = {'ex': 'http://example.com/ns'}
ids = root.xpath('ex:thing/@id', namespaces=ns)
assert ids == ['one', 'two'], ids
count = root.xpath('count(ex:thing)', namespaces=ns)
assert count == 2, count
PY
