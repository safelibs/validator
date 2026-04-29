#!/usr/bin/env bash
# @testcase: usage-python3-lxml-item-id-join
# @title: python3-lxml item id join
# @description: Collects item identifiers through lxml and verifies the joined id list.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-item-id-join"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

python3 - "$xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
root = etree.parse(sys.argv[1]).getroot()
print(','.join(node.get('id') for node in root.findall('item')))
PYCASE
validator_assert_contains "$tmpdir/out" 'a,b'
