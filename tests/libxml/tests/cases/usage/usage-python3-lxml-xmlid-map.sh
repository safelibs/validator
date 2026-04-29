#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xmlid-map
# @title: lxml XMLID map
# @description: Exercises lxml xmlid map through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xmlid-map"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root, ids = etree.XMLID(b'<root><item id="node-a">alpha</item></root>')
print(ids['node-a'].text)
PY
validator_assert_contains "$tmpdir/out" 'alpha'
