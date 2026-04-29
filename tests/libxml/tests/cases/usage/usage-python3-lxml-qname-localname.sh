#!/usr/bin/env bash
# @testcase: usage-python3-lxml-qname-localname
# @title: lxml QName localname
# @description: Exercises lxml qname localname through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-qname-localname"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
qname = etree.QName('urn:test', 'item')
print(qname.localname)
PY
validator_assert_contains "$tmpdir/out" 'item'
