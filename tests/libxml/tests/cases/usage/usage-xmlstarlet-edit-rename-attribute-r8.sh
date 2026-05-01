#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-rename-attribute-r8
# @title: xmlstarlet ed -r renames an attribute
# @description: Uses xmlstarlet ed -r against an attribute XPath to rename id to ref on every <item> element, verifying the new attribute name carries the original values, the old name is gone, and elements counted under the new name match the input.
# @timeout: 120
# @tags: usage, xml, cli, xmlstarlet
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <item id="a">alpha</item>
  <item id="b">beta</item>
  <item id="c">gamma</item>
</root>
XML

xmlstarlet ed -r '//item/@id' -v 'ref' "$tmpdir/in.xml" >"$tmpdir/out.xml"

new_count=$(xmlstarlet sel -t -v 'count(//item[@ref])' "$tmpdir/out.xml")
old_count=$(xmlstarlet sel -t -v 'count(//item[@id])' "$tmpdir/out.xml")
[[ "$new_count" == "3" ]] || { printf 'expected 3 items with @ref, got %s\n' "$new_count" >&2; exit 1; }
[[ "$old_count" == "0" ]] || { printf 'expected 0 items still carrying @id, got %s\n' "$old_count" >&2; exit 1; }

first_ref=$(xmlstarlet sel -t -v '/root/item[1]/@ref' "$tmpdir/out.xml")
last_ref=$(xmlstarlet sel -t -v '/root/item[last()]/@ref' "$tmpdir/out.xml")
[[ "$first_ref" == "a" ]] || { printf 'first @ref mismatch: %s\n' "$first_ref" >&2; exit 1; }
[[ "$last_ref" == "c" ]] || { printf 'last @ref mismatch: %s\n' "$last_ref" >&2; exit 1; }
