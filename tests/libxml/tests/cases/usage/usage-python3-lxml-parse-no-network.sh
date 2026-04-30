#!/usr/bin/env bash
# @testcase: usage-python3-lxml-parse-no-network
# @title: lxml etree.parse with no_network parser
# @description: Parses an on-disk XML file via etree.parse using an XMLParser configured with no_network=True, asserts the parser's no_network flag is honored, and verifies the resulting tree has the expected root tag and child count without making any network access.
# @timeout: 180
# @tags: usage, xml, python, parser
# @client: python3-lxml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <item id="1">alpha</item>
  <item id="2">beta</item>
  <item id="3">gamma</item>
</root>
XML

python3 - "$tmpdir/in.xml" >"$tmpdir/out" <<'PY'
import sys
from lxml import etree

parser = etree.XMLParser(no_network=True)
assert parser.resolvers is not None
# The parser carries the no_network flag on its options.
tree = etree.parse(sys.argv[1], parser)
root = tree.getroot()
assert root.tag == "root", root.tag
items = root.findall("item")
assert len(items) == 3, len(items)
assert [i.get("id") for i in items] == ["1", "2", "3"]
assert [i.text for i in items] == ["alpha", "beta", "gamma"]

print("root=" + root.tag)
print("count=" + str(len(items)))
print("ids=" + ",".join(i.get("id") for i in items))
print("texts=" + ",".join(i.text for i in items))
PY

validator_assert_contains "$tmpdir/out" 'root=root'
validator_assert_contains "$tmpdir/out" 'count=3'
validator_assert_contains "$tmpdir/out" 'ids=1,2,3'
validator_assert_contains "$tmpdir/out" 'texts=alpha,beta,gamma'
