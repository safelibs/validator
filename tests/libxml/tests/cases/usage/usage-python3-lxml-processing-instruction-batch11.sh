#!/usr/bin/env bash
# @testcase: usage-python3-lxml-processing-instruction-batch11
# @title: lxml processing instruction
# @description: Reads a processing instruction target and text through lxml.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-processing-instruction-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

python3 - "$tmpdir/items.xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
root = etree.parse(sys.argv[1]).getroot()
pi = root.xpath('//processing-instruction()')[0]
print(pi.target + ':' + pi.text)
PYCASE
validator_assert_contains "$tmpdir/out" 'note:ok'
