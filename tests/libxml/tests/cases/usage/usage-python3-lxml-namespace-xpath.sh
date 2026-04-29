#!/usr/bin/env bash
# @testcase: usage-python3-lxml-namespace-xpath
# @title: lxml namespace XPath
# @description: Evaluates a namespace-aware XPath expression with python3-lxml.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-namespace-xpath"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root xmlns:a="urn:a"><a:item>value</a:item></root>')
print(root.xpath('string(/root/a:item)', namespaces={'a': 'urn:a'}))
PY
validator_assert_contains "$tmpdir/out" 'value'
