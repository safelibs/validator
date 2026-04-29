#!/usr/bin/env bash
# @testcase: usage-python3-lxml-elementpath-findtext
# @title: lxml elementpath findtext
# @description: Exercises lxml elementpath findtext through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-elementpath-findtext"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root><group><item>beta</item></group></root>')
print(root.findtext('group/item'))
PY
validator_assert_contains "$tmpdir/out" 'beta'
