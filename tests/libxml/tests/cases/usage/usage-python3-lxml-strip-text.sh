#!/usr/bin/env bash
# @testcase: usage-python3-lxml-strip-text
# @title: lxml normalize-space text
# @description: Uses lxml XPath normalize-space to trim XML text content and verifies the normalized result.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-strip-text"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
root = etree.XML(b'<root>  spaced text  </root>')
print(root.xpath('normalize-space(/root)'))
PY
validator_assert_contains "$tmpdir/out" 'spaced text'
