#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r15-sel-count-attribute-predicate
# @title: xmlstarlet sel count(//item[@type='x']) returns the count of attribute-matching elements
# @description: Runs xmlstarlet sel with an XPath count() over a predicate that filters elements by an attribute value, and asserts the captured stdout equals the number of matching nodes (here, 2). Pins the XPath count() and predicate semantics through the xmlstarlet sel front-end.
# @timeout: 60
# @tags: usage, xmlstarlet, sel, xpath, count
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root>
  <item type="x">1</item>
  <item type="y">2</item>
  <item type="x">3</item>
</root>
XML

n=$(xmlstarlet sel -t -v "count(//item[@type='x'])" "$tmpdir/in.xml")
[[ "$n" == "2" ]] || {
    printf 'expected count=2, got %q\n' "$n" >&2
    exit 1
}

# And the complementary predicate equals 1.
m=$(xmlstarlet sel -t -v "count(//item[@type='y'])" "$tmpdir/in.xml")
[[ "$m" == "1" ]] || {
    printf 'expected count=1 for type=y, got %q\n' "$m" >&2
    exit 1
}
