#!/usr/bin/env bash
# @testcase: usage-xmlstarlet-r13-sel-concat-attrs-fn
# @title: xmlstarlet sel concat() builds a composite string from multiple attribute values
# @description: Selects items from a small XML file using xmlstarlet sel with an XPath concat() expression that interleaves attribute values and a literal separator, and asserts the emitted line for each item matches the expected "id=...|tier=..." composite string.
# @timeout: 60
# @tags: usage, xmlstarlet, select, xpath
# @client: xmlstarlet

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xml" <<'XML'
<catalog>
  <item id="a1" tier="gold"/>
  <item id="b2" tier="silver"/>
</catalog>
XML

xmlstarlet sel -t -m '/catalog/item' \
    -v 'concat("id=", @id, "|tier=", @tier)' -n \
    "$tmpdir/in.xml" >"$tmpdir/out"

[[ "$(sed -n '1p' "$tmpdir/out")" == "id=a1|tier=gold" ]] || {
    printf 'unexpected line 1: %q\n' "$(sed -n '1p' "$tmpdir/out")" >&2
    cat "$tmpdir/out" >&2
    exit 1
}
[[ "$(sed -n '2p' "$tmpdir/out")" == "id=b2|tier=silver" ]] || {
    printf 'unexpected line 2: %q\n' "$(sed -n '2p' "$tmpdir/out")" >&2
    cat "$tmpdir/out" >&2
    exit 1
}
