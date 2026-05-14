#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r17-ed-append-attribute-roundtrip
# @title: xmlstarlet ed -a appends a new element after a target node and survives a re-parse
# @description: Runs xmlstarlet ed -a to append a new <item> after an existing one in a small XML document, then re-parses the output with xmlstarlet sel to count <item> children and asserts the count grew by one.
# @timeout: 60
# @tags: usage, xmlstarlet, edit, append
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<?xml version="1.0"?>
<root>
  <item>a</item>
</root>
XML

before=$(xmlstarlet sel -t -v 'count(//item)' "$tmpdir/in.xml")
xmlstarlet ed -a '//item' -t elem -n 'item' -v 'b' "$tmpdir/in.xml" >"$tmpdir/out.xml"
after=$(xmlstarlet sel -t -v 'count(//item)' "$tmpdir/out.xml")

[[ "$before" == "1" ]] || { printf 'unexpected before count %s\n' "$before" >&2; exit 1; }
[[ "$after" == "2" ]] || {
    printf 'expected 2 items after append, got %s\n' "$after" >&2
    cat "$tmpdir/out.xml" >&2
    exit 1
}
