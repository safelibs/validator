#!/usr/bin/env bash
# @testcase: usage-python3-lxml-namespace-attribute
# @title: lxml namespaced attribute
# @description: Reads a namespaced XML attribute through lxml XPath and verifies the decoded attribute value.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-namespace-attribute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root xmlns:a="urn:a"><item a:status="ok"/></root>')
print(root.xpath('string(/root/item/@a:status)', namespaces={'a': 'urn:a'}))
PY
validator_assert_contains "$tmpdir/out" 'ok'
