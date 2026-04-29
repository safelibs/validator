#!/usr/bin/env bash
# @testcase: usage-python3-lxml-tostring-pretty
# @title: lxml tostring pretty
# @description: Exercises lxml tostring pretty through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-tostring-pretty"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><item>alpha</item></root>')
print(etree.tostring(root, pretty_print=True).decode())
PY
validator_assert_contains "$tmpdir/out" '<item>alpha</item>'
