#!/usr/bin/env bash
# @testcase: usage-python3-lxml-fromstring-attribute
# @title: python3-lxml fromstring attribute
# @description: Parses XML from bytes with lxml.fromstring and verifies an attribute value.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-fromstring-attribute"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/input.xml"
cat >"$xml" <<'XML'
<root xmlns:h="urn:hello"><item id="a">alpha</item><item id="b">beta</item><group active="yes"><value>3</value></group><h:note>hello-note</h:note></root>
XML

python3 - "$xml" >"$tmpdir/out" <<'PYCASE'
from lxml import etree
import sys
text = open(sys.argv[1], 'rb').read()
root = etree.fromstring(text)
print(root.find('group').get('active'))
PYCASE
validator_assert_contains "$tmpdir/out" 'yes'
