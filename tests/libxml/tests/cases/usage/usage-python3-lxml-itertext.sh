#!/usr/bin/env bash
# @testcase: usage-python3-lxml-itertext
# @title: python3-lxml itertext
# @description: Iterates text nodes with lxml and verifies the collected text order.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-itertext"
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
print('|'.join(text.strip() for text in root.itertext() if text.strip()))
PYCASE
validator_assert_contains "$tmpdir/out" 'alpha|beta|3|hello-note'
