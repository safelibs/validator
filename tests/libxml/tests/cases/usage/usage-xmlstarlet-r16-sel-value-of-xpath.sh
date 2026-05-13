#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r16-sel-value-of-xpath
# @title: xmlstarlet sel -t -v extracts the text value of an XPath-matched element
# @description: Runs xmlstarlet sel -t -v against an XPath that selects a specific <item> by attribute predicate, captures stdout, and asserts the output is exactly that element's text content with no surrounding markup.
# @timeout: 60
# @tags: usage, xmlstarlet, sel, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root>
  <item id="a">alpha</item>
  <item id="b">bravo</item>
  <item id="c">charlie</item>
</root>
XML

xmlstarlet sel -t -v '//item[@id="b"]' -n "$tmpdir/in.xml" >"$tmpdir/out"

# Result must be exactly the matched element text, no markup leakage.
val=$(<"$tmpdir/out")
[[ "$val" == "bravo" ]] || {
    printf 'expected "bravo", got %q\n' "$val" >&2
    cat "$tmpdir/out" >&2
    exit 1
}
