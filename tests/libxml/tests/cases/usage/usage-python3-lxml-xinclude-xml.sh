#!/usr/bin/env bash
# @testcase: usage-python3-lxml-xinclude-xml
# @title: python3-lxml XInclude XML expansion
# @description: Runs lxml XInclude expansion and verifies included XML element text is visible to the client.
# @timeout: 180
# @tags: usage, xml
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/main.xml" <<'XML'
<root xmlns:xi="http://www.w3.org/2001/XInclude">
  <xi:include href="fragment.xml" parse="xml"/>
</root>
XML

cat >"$tmpdir/fragment.xml" <<'XML'
<included>fragment-value</included>
XML

python3 - <<'PY' "$tmpdir/main.xml" | tee "$tmpdir/out"
from lxml import etree
import sys

tree = etree.parse(sys.argv[1])
tree.xinclude()
text = tree.xpath("string(/root/included)")
assert text == "fragment-value", text
print(text)
PY

validator_assert_contains "$tmpdir/out" 'fragment-value'
