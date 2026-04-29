#!/usr/bin/env bash
# @testcase: usage-python3-lxml-recover-parser
# @title: lxml recover parser
# @description: Parses malformed XML with lxml recovery enabled and verifies recovered content.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-recover-parser"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
from lxml import etree
parser = etree.XMLParser(recover=True)
root = etree.fromstring(b'<root><item>ok</root>', parser)
print(root.xpath('string(item)'))
PY
validator_assert_contains "$tmpdir/out" 'ok'
