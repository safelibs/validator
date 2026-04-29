#!/usr/bin/env bash
# @testcase: usage-python3-lxml-iterparse
# @title: lxml iterparse
# @description: Iterates over XML elements with lxml iterparse and verifies parsed tag names.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-iterparse"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from io import BytesIO
from lxml import etree
tags = [element.tag for _, element in etree.iterparse(BytesIO(b'<root><item>a</item><item>b</item></root>'))]
print(",".join(tags))
PY
validator_assert_contains "$tmpdir/out" 'item'
