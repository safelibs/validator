#!/usr/bin/env bash
# @testcase: usage-python3-lxml-cdata-serialize
# @title: lxml CDATA serialize
# @description: Exercises lxml cdata serialize through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-cdata-serialize"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.Element('root')
root.text = etree.CDATA('alpha<beta>')
print(etree.tostring(root).decode())
PY
validator_assert_contains "$tmpdir/out" '<![CDATA[alpha<beta>]]>'
