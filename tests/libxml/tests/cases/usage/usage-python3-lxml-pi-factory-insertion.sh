#!/usr/bin/env bash
# @testcase: usage-python3-lxml-pi-factory-insertion
# @title: lxml etree.PI factory and insertion
# @description: Creates a processing instruction node through the etree.PI(target, text) factory, inserts it as the first child of an element via insert(), and verifies the serialized output places the PI at the expected position with the correct target and content.
# @timeout: 180
# @tags: usage, xml, python, processing-instruction
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - >"$tmpdir/out" <<'PY'
from lxml import etree

root = etree.Element("root")
etree.SubElement(root, "first").text = "1"
etree.SubElement(root, "second").text = "2"

pi = etree.PI("xml-stylesheet", 'type="text/xsl" href="style.xsl"')
assert pi.target == "xml-stylesheet", pi.target
assert pi.text == 'type="text/xsl" href="style.xsl"', pi.text

# Insert as the first child of root.
root.insert(0, pi)

assert root[0].tag is etree.ProcessingInstruction
assert root[0].target == "xml-stylesheet"

xml = etree.tostring(root, encoding="unicode")
assert xml.startswith('<root><?xml-stylesheet '), xml
assert '<?xml-stylesheet type="text/xsl" href="style.xsl"?>' in xml, xml
# The PI sits before the <first> sibling.
assert xml.index('<?xml-stylesheet') < xml.index('<first>'), xml

print("xml=" + xml)
print("target=" + pi.target)
PY

validator_assert_contains "$tmpdir/out" '<?xml-stylesheet type="text/xsl" href="style.xsl"?>'
validator_assert_contains "$tmpdir/out" 'target=xml-stylesheet'
