#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xpath-count
# @title: python3-lxml XPath count
# @description: Evaluates an XPath count through lxml and verifies the numeric result.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-xpath-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

python3 - "$xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
root = etree.parse(sys.argv[1])
print(int(root.xpath('count(/root/item)')))
PYCASE
validator_assert_contains "$tmpdir/out" '2'
