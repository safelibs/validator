#!/usr/bin/env bash
# @testcase: usage-python3-lxml-remove-comments-parser-batch11
# @title: lxml remove comments parser
# @description: Parses XML with lxml while removing comment nodes.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-remove-comments-parser-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

python3 - "$tmpdir/items.xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
parser = etree.XMLParser(remove_comments=True)
root = etree.parse(sys.argv[1], parser).getroot()
print(len(root.xpath('//comment()')))
PYCASE
validator_assert_contains "$tmpdir/out" '0'
