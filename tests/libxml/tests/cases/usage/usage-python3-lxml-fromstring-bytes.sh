#!/usr/bin/env bash
# @testcase: usage-python3-lxml-fromstring-bytes
# @title: lxml fromstring bytes
# @description: Exercises lxml fromstring bytes through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-fromstring-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.fromstring(b'<root><item>alpha</item></root>')
print(root.findtext('item'))
PY
validator_assert_contains "$tmpdir/out" 'alpha'
