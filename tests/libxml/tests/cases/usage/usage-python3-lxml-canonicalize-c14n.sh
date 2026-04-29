#!/usr/bin/env bash
# @testcase: usage-python3-lxml-canonicalize-c14n
# @title: lxml canonicalize c14n
# @description: Canonicalizes XML with python3-lxml's etree.canonicalize and verifies the attributes are reordered alphabetically.
# @timeout: 180
# @tags: usage, xml, python
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-canonicalize-c14n"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

xml="$tmpdir/doc.xml"
cat >"$xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root xmlns:m="urn:meta">
  <item id="a" weight="2">alpha</item>
  <item id="b" weight="3">beta</item>
  <item id="c" weight="5">gamma</item>
  <m:tag>meta-tag</m:tag>
</root>
XML

python3 >"$tmpdir/out" <<'PYCASE'
from lxml import etree
xml = '<root b="2" a="1"><item>ok</item></root>'
print(etree.canonicalize(xml))
PYCASE
validator_assert_contains "$tmpdir/out" '<root a="1" b="2">'
