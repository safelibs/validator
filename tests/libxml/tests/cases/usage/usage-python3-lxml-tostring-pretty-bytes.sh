#!/usr/bin/env bash
# @testcase: usage-python3-lxml-tostring-pretty-bytes
# @title: lxml tostring pretty_print exact bytes
# @description: Serializes a small lxml tree with etree.tostring(pretty_print=True) and verifies the exact byte-for-byte output, asserting indentation and newline placement match the documented libxml2 pretty-printer behavior.
# @timeout: 120
# @tags: usage, xml, python, serialize
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-lxml-tostring-pretty-bytes"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' >"$tmpdir/out.xml"
import sys
from lxml import etree
root = etree.Element('root')
a = etree.SubElement(root, 'item', id='1')
a.text = 'alpha'
b = etree.SubElement(root, 'item', id='2')
b.text = 'beta'
sys.stdout.buffer.write(etree.tostring(root, pretty_print=True))
PY

cat >"$tmpdir/expected.xml" <<'XML'
<root>
  <item id="1">alpha</item>
  <item id="2">beta</item>
</root>
XML

diff -u "$tmpdir/expected.xml" "$tmpdir/out.xml"

# Exact byte match (no trailing whitespace surprises).
expected_size=$(wc -c <"$tmpdir/expected.xml")
actual_size=$(wc -c <"$tmpdir/out.xml")
[[ "$expected_size" == "$actual_size" ]] || {
  printf 'pretty_print byte size mismatch: expected=%s actual=%s\n' "$expected_size" "$actual_size" >&2
  exit 1
}
