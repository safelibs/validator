#!/usr/bin/env bash
# @testcase: usage-python3-lxml-objectify-attribute-batch11
# @title: lxml objectify attribute
# @description: Reads an XML attribute through lxml.objectify.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-objectify-attribute-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/items.xml" <<'XML'
<root><item id="a" weight="2">Alpha</item><item id="b" weight="3">Beta</item><!--drop--><?note ok?></root>
XML

python3 >"$tmpdir/out" <<'PYCASE'
from lxml import objectify
root = objectify.fromstring(b'<root><item code="x">7</item></root>')
print(root.item.get('code'))
PYCASE
validator_assert_contains "$tmpdir/out" 'x'
