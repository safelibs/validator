#!/usr/bin/env bash
# @testcase: usage-python3-lxml-itertext-join
# @title: lxml itertext join
# @description: Iterates mixed XML text content through lxml itertext and verifies the concatenated text order.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-itertext-join"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root>alpha<item>beta</item>gamma</root>')
print("|".join(root.itertext()))
PY
validator_assert_contains "$tmpdir/out" 'alpha|beta|gamma'
