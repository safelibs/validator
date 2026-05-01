#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-edit-insert-pi-r7
# @title: xmlstarlet ed -s subnode text + attr combined
# @description: Uses xmlstarlet ed to combine a text-typed subnode insertion (-s -t text) with an attribute insertion (-i -t attr) in a single invocation, then verifies the rewritten document contains the expected text content and attribute values via xmlstarlet sel.
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
  <item id="a"/>
</root>
XML

# Insert a text subnode under <item>, then add a 'lang' attribute to it.
xmlstarlet ed \
  -s '/root/item' -t text -n '' -v 'alpha-content' \
  -i '/root/item' -t attr -n 'lang' -v 'en' \
  "$tmpdir/in.xml" >"$tmpdir/out.xml"

validator_require_file "$tmpdir/out.xml"

# Confirm the text subnode landed inside <item>.
text=$(xmlstarlet sel -t -v 'string(/root/item)' "$tmpdir/out.xml")
[[ "$text" == "alpha-content" ]] || {
  printf 'expected item text "alpha-content", got %q\n' "$text" >&2
  cat "$tmpdir/out.xml" >&2
  exit 1
}

# Confirm both attributes are present with the expected values.
id_val=$(xmlstarlet sel -t -v '/root/item/@id' "$tmpdir/out.xml")
lang_val=$(xmlstarlet sel -t -v '/root/item/@lang' "$tmpdir/out.xml")
[[ "$id_val" == "a" ]] || { printf 'id mismatch: %s\n' "$id_val" >&2; exit 1; }
[[ "$lang_val" == "en" ]] || { printf 'lang mismatch: %s\n' "$lang_val" >&2; exit 1; }

# Single-pass mutation should leave exactly one <item> with both attributes.
count=$(xmlstarlet sel -t -v 'count(/root/item[@id and @lang])' "$tmpdir/out.xml")
[[ "$count" == "1" ]] || { printf 'expected 1 item with both attrs, got %s\n' "$count" >&2; exit 1; }
